shader_type spatial;
render_mode skip_vertex_transform, diffuse_lambert_wrap, vertex_lighting, cull_disabled, shadows_disabled, ambient_light_disabled;

uniform float precision_multiplier = 2.;
uniform vec4 modulate_color : hint_color = vec4(1.0);
uniform sampler2D albedoTex : hint_albedo;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
uniform int color_depth = 15;
uniform bool dither_enabled = true;
uniform bool fog_enabled = true;
uniform vec4 fog_color : hint_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform float min_fog_distance : hint_range(0, 100) = 10;
uniform float max_fog_distance : hint_range(0, 100) = 40;
uniform vec2 uv_pan_velocity = vec2(0.0);

varying float fog_weight;
varying float vertex_distance;

float inv_lerp(float from, float to, float value)
{
	return (value - from) / (to - from);
}

// originally based on: https://github.com/marmitoTH/godot-psx-shaders/
const float psx_fixed_point_precision = 16.16;
void vertex()
{
	UV = UV * uv_scale + uv_offset;
	UV += uv_pan_velocity * TIME;

	// Vertex snapping
	// based on https://github.com/BroMandarin/unity_lwrp_psx_shader/blob/master/PS1.shader
	float vertex_snap_step = psx_fixed_point_precision * precision_multiplier;
	vec4 snap_to_pixel = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_vertex = snap_to_pixel;
	clip_vertex.xyz = snap_to_pixel.xyz / snap_to_pixel.w;
	clip_vertex.x = floor(vertex_snap_step * clip_vertex.x) / vertex_snap_step;
	clip_vertex.y = floor(vertex_snap_step * clip_vertex.y) / vertex_snap_step;
	clip_vertex.xyz *= snap_to_pixel.w;
	POSITION = clip_vertex;
	POSITION /= abs(POSITION.w);

	VERTEX = VERTEX;  // it breaks without this
	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vertex_distance = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));

	fog_weight = inv_lerp(min_fog_distance, max_fog_distance, vertex_distance);
	fog_weight = clamp(fog_weight, 0, 1);
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
	ALBEDO = COLOR.rgb;
	ALBEDO *= (texture(albedoTex, UV) * modulate_color).rgb;
	ALBEDO = fog_enabled ? mix(ALBEDO, fog_color.rgb, fog_weight) : ALBEDO;
	ALBEDO = dither_enabled ? ALBEDO * get_dither_brightness(ALBEDO, FRAGCOORD) : ALBEDO;
	ALBEDO = band_color(ALBEDO, color_depth);
}
