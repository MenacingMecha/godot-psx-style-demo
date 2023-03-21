#pragma disable_preprocessor
shader_type canvas_item;

uniform vec2 blur_scale = vec2(0.5, 0.5);
uniform float blur_samples = 50.0;
uniform float blur_brightness = 1.65;
uniform bool enabled = true;

const float PI2 = 6.283185307179586476925286766559;

// 2-pass gaussian blur based on https://github.com/GDQuest/godot-shaders/blob/master/godot/Shaders/gaussian_blur.shader
// TODO: change to this algorithm https://github.com/GDQuest/godot-shaders/blob/master/godot/Shaders/gaussian_blur_optimized.shader
float gaussian(float x)
{
	float x_squared = x*x;
	float width = 1.0 / sqrt(PI2 * blur_samples);

	return width * exp((x_squared / (2.0 * blur_samples)) * -1.0);
}

vec4 gaussian_blur_pass(vec2 texture_pixel_size, sampler2D texture, vec2 uv, float _blur_samples)
{
    float weight = 0.0;
    float total_weight = 0.0;
    vec2 scale_horiz = texture_pixel_size * vec2(blur_scale.x, 0.0);
    vec4 color_horiz = vec4(0.0);

    for(int i=-int(_blur_samples)/2; i < int(_blur_samples)/2; ++i) {
        weight = gaussian(float(i));
        color_horiz += texture(texture, uv + scale_horiz * vec2(float(i))) * weight;
        total_weight += weight;
    }

    weight = 0.0;
    total_weight = 0.0;
    vec2 scale_vert = texture_pixel_size * vec2(0.0, blur_scale.y);
    vec4 color_vert = vec4(0.0);

    for(int i=-int(_blur_samples)/2; i < int(_blur_samples)/2; ++i) {
        weight = gaussian(float(i));
        color_vert += texture(texture, uv + scale_vert * vec2(float(i))) * weight;
        total_weight += weight;
    }

    vec4 blur_horiz = color_horiz / total_weight;
    vec4 blur_vert = color_vert / total_weight;
    vec4 blur = mix(color_horiz, color_vert, 0.5);
    return blur;
}

void fragment()
{
    COLOR = enabled ? gaussian_blur_pass(TEXTURE_PIXEL_SIZE, TEXTURE, UV, blur_samples) * blur_brightness : texture(TEXTURE, UV);
}
