shader_type spatial;
render_mode
	diffuse_lambert_wrap, unshaded, depth_draw_alpha_prepass;

uniform vec2 precision_ratio = vec2(4.0, 3.0);
uniform float precision_height = 240.0;
uniform float precision_multiplier = 1.;
uniform vec4 modulate_color : hint_color = vec4(1.);
uniform sampler2D albedoTex : hint_albedo;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
uniform vec2 uv_pan_velocity = vec2(0.0);
uniform bool billboard = false;
uniform bool y_billboard = false;
uniform float alpha_scissor : hint_range(0, 1) = 0.1;
uniform bool dither_enabled = true;
uniform int color_depth = 15;
uniform bool fog_enabled = true;
uniform vec4 fog_color : hint_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform float min_fog_distance : hint_range(0, 100) = 10;
uniform float max_fog_distance : hint_range(0, 100) = 40;
uniform bool draw_distance_enabled = true;
uniform float draw_distance : hint_range(0, 100) = 10.0;

varying float fog_weight;
varying float vertex_distance;
varying float origin_distance;

vec2 get_vertex_snap_step()
{
	return vec2(length(normalize(precision_ratio)) * precision_height, precision_height) * precision_multiplier;
}

float inv_lerp(float from, float to, float value)
{
	return (value - from) / (to - from);
}

// https://stackoverflow.com/a/42470600
vec4 band_color(vec4 _color, int num_of_colors)
{
	vec4 num_of_colors_vec = vec4(float(num_of_colors));
	return floor(_color * num_of_colors_vec) / num_of_colors_vec;
}

float get_dither_brightness(vec4 tex, vec4 fragcoord)
{
	const float pos_mult = 1.0;
	vec4 position_new = fragcoord * pos_mult;
	int x = int(position_new.x) % 4;
	int y = int(position_new.y) % 4;
	const float luminance_r = 0.2126;
	const float luminance_g = 0.7152;
	const float luminance_b = 0.0722;
	float brightness = (luminance_r * tex.r) + (luminance_g * tex.g) + (luminance_b * tex.b);

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

// https://github.com/marmitoTH/godot-psx-shaders/
void vertex()
{
	UV = UV * uv_scale + uv_offset;
	UV += uv_pan_velocity * TIME;

	if (y_billboard)
	{
		MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],WORLD_MATRIX[1],vec4(normalize(cross(CAMERA_MATRIX[0].xyz,WORLD_MATRIX[1].xyz)), 0.0),WORLD_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(1.0, 0.0, 0.0, 0.0),vec4(0.0, 1.0/length(WORLD_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0 ,1.0));
	}
	else if (billboard)
	{
		MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
	}

	// Vertex snapping
	// Based on https://github.com/BroMandarin/unity_lwrp_psx_shader/blob/master/PS1.shader
	vec2 vertex_snap_step = get_vertex_snap_step();
	vec4 snap_to_pixel = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_vertex = snap_to_pixel;
	clip_vertex.xyz = snap_to_pixel.xyz / snap_to_pixel.w;
	clip_vertex.xy = floor(vertex_snap_step * clip_vertex.xy) / vertex_snap_step;
	clip_vertex.xyz *= snap_to_pixel.w;
	POSITION = clip_vertex;
	POSITION /= abs(POSITION.w);

	// Recalculate normal with new position
	// Source: https://forum.unity.com/threads/shader-question-how-to-recalculate-normals-after-vertices-displacement.903248/
	vec3 bitangent = cross(NORMAL, TANGENT.xyz);
	vec3 nt = ((POSITION.xyz + TANGENT.xyz * 0.01) - POSITION.xyz );
	vec3 nb = ((POSITION.xyz + bitangent * 0.01) - POSITION.xyz );
	NORMAL = cross(nt, nb);

	if (y_billboard)
	{
		MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(WORLD_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(WORLD_MATRIX[1].xyz), 0.0, 0.0),vec4(0.0, 0.0, length(WORLD_MATRIX[2].xyz), 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	}

	VERTEX = VERTEX;  // it breaks without this
	vertex_distance = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
	origin_distance = length((MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)));

	fog_weight = inv_lerp(min_fog_distance, max_fog_distance, vertex_distance);
	fog_weight = clamp(fog_weight, 0, 1);
}

void fragment()
{
	if (draw_distance_enabled && origin_distance > draw_distance) discard;

	vec4 tex = texture(albedoTex, UV) * modulate_color;
	tex = fog_enabled ? mix(tex, fog_color, fog_weight) : tex;
	tex = dither_enabled ? tex * get_dither_brightness(tex, FRAGCOORD) : tex;
	tex = band_color(tex, color_depth);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	ALPHA_SCISSOR = alpha_scissor;
}