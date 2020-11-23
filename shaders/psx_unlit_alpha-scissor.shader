shader_type spatial;
render_mode skip_vertex_transform, diffuse_lambert_wrap, unshaded;

uniform float precision_multiplier = 2.;
uniform vec4 modulate_color : hint_color = vec4(1.);
uniform sampler2D albedoTex : hint_albedo;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
uniform bool billboard = false;
uniform bool y_billboard = false;
uniform int color_depth = 15;
uniform float alpha_scissor : hint_range(0, 1) = 0.1;

// https://stackoverflow.com/a/42470600
vec4 band_color(vec4 _color, int num_of_colors)
{
	vec4 num_of_colors_vec = vec4(float(num_of_colors));
	return floor(_color * num_of_colors_vec) / num_of_colors_vec;
}

// https://github.com/marmitoTH/godot-psx-shaders/
const float psx_fixed_point_precision = 16.16;
void vertex()
{
	UV = UV * uv_scale + uv_offset;

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
	float vertex_snap_step = psx_fixed_point_precision * precision_multiplier;
	vec4 snap_to_pixel = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_vertex = snap_to_pixel;
	clip_vertex.xyz = snap_to_pixel.xyz / snap_to_pixel.w;
	clip_vertex.x = floor(vertex_snap_step * clip_vertex.x) / vertex_snap_step;
	clip_vertex.y = floor(vertex_snap_step * clip_vertex.y) / vertex_snap_step;
	clip_vertex.xyz *= snap_to_pixel.w;
	POSITION = clip_vertex;
	POSITION /= abs(POSITION.w);

	if (y_billboard)
	{
		MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(WORLD_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(WORLD_MATRIX[1].xyz), 0.0, 0.0),vec4(0.0, 0.0, length(WORLD_MATRIX[2].xyz), 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	}
}

void fragment()
{
	vec4 tex = texture(albedoTex, UV) * modulate_color;
	tex = band_color(tex, color_depth);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	ALPHA_SCISSOR = alpha_scissor;
}