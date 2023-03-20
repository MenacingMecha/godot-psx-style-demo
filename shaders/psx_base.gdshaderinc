#if defined(LIT)
render_mode diffuse_lambert, vertex_lighting, cull_disabled, shadows_disabled, depth_draw_opaque;
#elif defined(UNLIT)
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque;
#endif

uniform float precision_multiplier : hint_range(0.0, 1.0) = 1.0;
uniform vec4 modulate_color : source_color = vec4(1.0);

#ifndef NO_TEXTURE
uniform sampler2D albedoTex : source_color, filter_nearest, repeat_enable;
#endif

// METAL doesn't use UV, so no need for panning properties
#ifndef METAL
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
uniform vec2 uv_pan_velocity = vec2(0.0);
#endif

// https://github.com/dsoft20/psx_retroshader/blob/master/Assets/Shaders/psx-vertexlit.shader
const vec2 base_snap_res = vec2(160.0, 120.0);
vec4 get_snapped_pos(vec4 base_pos)
{
	vec4 snapped_pos = base_pos;
	snapped_pos.xyz = base_pos.xyz / base_pos.w; // convert to normalised device coordinates (NDC)
	vec2 snap_res = floor(base_snap_res * precision_multiplier);  // increase "snappy-ness"
	snapped_pos.x = floor(snap_res.x * snapped_pos.x) / snap_res.x;  // snap the base_pos to the lower-vertex_resolution grid
	snapped_pos.y = floor(snap_res.y * snapped_pos.y) / snap_res.y;
	snapped_pos.xyz *= base_pos.w;  // convert back to projection-space
	return snapped_pos;
}

void vertex()
{
// METAL doesn't use UV, so no need to pan UVs
#if defined(NO_TEXTURE) || !defined(METAL)
	UV = UV * uv_scale + uv_offset;
	UV += uv_pan_velocity * TIME;
#endif

	POSITION = get_snapped_pos(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));  // snap position to grid
	POSITION /= abs(POSITION.w);  // discard depth for affine mapping

	VERTEX = VERTEX;  // it breaks without this - not sure why
}

void fragment()
{
#ifdef METAL
	vec2 texture_uv = vec2(NORMAL.x / 2.0 + 0.5, (-NORMAL.y) / 2.0 + 0.5);  // Special thanks to Adam McLaughlan
#elif !defined(NO_TEXTURE)
	vec2 texture_uv = UV;
#endif

	vec4 color_base = COLOR * modulate_color;

#ifdef NO_TEXTURE
	ALBEDO = color_base.rgb;
#else
	ALBEDO = (color_base * texture(albedoTex, texture_uv)).rgb;
#endif

#ifdef LIGHT_VOLUME
	ALPHA = 1.0 - UV.y;
#endif
}
