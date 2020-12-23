shader_type spatial;
render_mode skip_vertex_transform, diffuse_lambert_wrap, unshaded, cull_disabled;

uniform vec2 precision_ratio = vec2(4.0, 3.0);
uniform float precision_height = 240.0;
uniform float precision_multiplier = 1.;
uniform vec4 modulate_color : hint_color = vec4(1.0);
uniform vec4 metal_modulate_color : hint_color = vec4(1.0);
uniform samplerCube cubemap;
uniform vec3 cubemap_uv_scale = vec3(1.0);
uniform int color_depth = 15;
uniform bool dither_enabled = true;
uniform bool fog_enabled = true;
uniform vec4 fog_color : hint_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform float min_fog_distance : hint_range(0, 100) = 10;
uniform float max_fog_distance : hint_range(0, 100) = 40;

varying vec3 cubemap_UV;
varying float fog_weight;
varying float vertex_distance;

vec2 get_vertex_snap_step()
{
	return vec2(length(normalize(precision_ratio)) * precision_height, precision_height) * precision_multiplier;
}

float inv_lerp(float from, float to, float value)
{
	return (value - from) / (to - from);
}

// originally based on: https://github.com/marmitoTH/godot-psx-shaders/
void vertex()
{
	// Vertex snapping
	// based on https://github.com/BroMandarin/unity_lwrp_psx_shader/blob/master/PS1.shader
	vec2 vertex_snap_step = get_vertex_snap_step();
	vec4 snap_to_pixel = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_vertex = snap_to_pixel;
	clip_vertex.xyz = snap_to_pixel.xyz / snap_to_pixel.w;
	clip_vertex.xy = floor(vertex_snap_step * clip_vertex.xy) / vertex_snap_step;
	clip_vertex.xyz *= snap_to_pixel.w;
	POSITION = clip_vertex;
	POSITION /= abs(POSITION.w);

	VERTEX = VERTEX;  // it breaks without this
	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vertex_distance = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));

	fog_weight = inv_lerp(min_fog_distance, max_fog_distance, vertex_distance);
	fog_weight = clamp(fog_weight, 0, 1);

	// define cubemap UV
	// https://godotforums.org/discussion/15406/cubemap-reflections-cubic-environment-mapping
	vec4 invcamx = INV_CAMERA_MATRIX[0];
	vec4 invcamy = INV_CAMERA_MATRIX[1];
	vec4 invcamz = INV_CAMERA_MATRIX[2];
	vec4 invcamw = INV_CAMERA_MATRIX[3];

	vec3 CameraPosition = -invcamw.xyz * mat3( invcamx.xyz, invcamy.xyz, invcamz.xyz );

	vec3 vertexW = (WORLD_MATRIX * vec4(VERTEX, 0.0)).xyz; 		//vertex from model to world space
	vec3 N = normalize(WORLD_MATRIX * vec4(NORMAL.x, NORMAL.y, NORMAL.z, 0.0)).xyz;	//normal from model space to world space
	vec3 I = normalize(vertexW - CameraPosition);				//incident vector (from camera to vertex)
	vec3 R = reflect(I, N);					//reflection vector (from vertex to cube map)
	R.z *= -1.0;
	cubemap_UV = R;
}

float get_dither_brightness(vec3 albedo, vec4 fragcoord)
{
	const float pos_mult = 1.0;
	vec4 position_new = fragcoord * pos_mult;
	int x = int(position_new.x) % 4;
	int y = int(position_new.y) % 4;
	const float luminance_r = 0.2126;
	const float luminance_g = 0.7152;
	const float luminance_b = 0.0722;
	float brightness = (luminance_r * albedo.r) + (luminance_g * albedo.g) + (luminance_b * albedo.b);

	// as of 3.2.2, matrix indices can only be accessed with constants, leading to this fun
	float thresholdMatrix[16] = float[16] (
		1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
		13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
		4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
		16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
	);

	float dithering = thresholdMatrix[x * 4 + y];
	const float brightness_mod = 0.2;
	const float dither_cull_distance = 60.;
	if ((brightness - brightness_mod < dithering) && (vertex_distance < dither_cull_distance))
	{
		const float dithering_effect_size = 0.25;
		return ((dithering - 0.5) * dithering_effect_size) + 1.0;
	}
	else
	{
		return 1.;
	}
}

// https://stackoverflow.com/a/42470600
vec3 band_color(vec3 _color, int num_of_colors)
{
	vec3 num_of_colors_vec = vec3(float(num_of_colors));
	return floor(_color * num_of_colors_vec) / num_of_colors_vec;
}

void fragment()
{
	ALBEDO = (COLOR * modulate_color).rgb;
	vec4 tex = texture(cubemap, cubemap_UV * cubemap_uv_scale) * metal_modulate_color;
	ALBEDO *= tex.rgb;
	ALBEDO = fog_enabled ? mix(ALBEDO, fog_color.rgb, fog_weight) : ALBEDO;
	ALBEDO = dither_enabled ? ALBEDO * get_dither_brightness(ALBEDO, FRAGCOORD) : ALBEDO;
	ALBEDO = band_color(ALBEDO, color_depth);
}
