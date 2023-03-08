shader_type canvas_item;
// originally based on https://github.com/WittyCognomen/godot-psx-shaders-demo/blob/master/shaders/psx_dither_post.shader

uniform sampler2D dither_tex: hint_white;
uniform float col_depth = 15.0;
uniform bool dither_banding = true;

void fragment() {
	vec2 dith_size = vec2(textureSize(dither_tex,0)); // for GLES2: substitute for the dimensions of the dithering matrix
	vec2 buf_size = vec2(textureSize(TEXTURE,0));
	
	COLOR = texture(TEXTURE, SCREEN_UV);

	vec3 dith = texture(dither_tex, SCREEN_UV*(buf_size/dith_size)).rgb;
	dith -= 0.5;
	COLOR.rgb = round(COLOR.rgb*col_depth + dith * (dither_banding ? 1.0 : 0.0)) / col_depth;
}
