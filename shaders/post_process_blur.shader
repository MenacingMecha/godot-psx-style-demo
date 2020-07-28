shader_type canvas_item;

uniform vec3 hdr_threshold = vec3(0.7);
uniform float exposure;
uniform float hdr_threshold_float = 1.0;
uniform vec2 blur_scale = vec2(0.5, 0.5);
uniform float blur_samples = 50.0;
uniform float blur_brightness = 1.65;
uniform bool enabled = true;

const float PI2 = 6.283185307179586476925286766559;

vec4 get_hdr_pass(vec4 tex, vec3 _hdr_threshold)
{
    // const vec3 hdr_threshold = vec3(0.2126, 0.7152, 0.0722);
    // float brightness = dot(tex.rgb, _hdr_threshold);
    // float brightness = dot(_hdr_threshold, tex.rgb + vec3(1.0));
    // float brightness = dot(tex.rgb - vec3(1.0), _hdr_threshold);
    // vec3 hdr = vec3(1.0) - _hdr_threshold;
    // if(brightness > 1.0)
    //     BrightColor = vec4(FragColor.rgb, 1.0);
    // else
    //     BrightColor = vec4(0.0, 0.0, 0.0, 1.0);
    // bool passes_hdr = tex.rgb - hdr_threshold > ;
    // return brightness > 1.0 ? vec4(tex.rgb, 1.0) : vec4(0.0, 0.0, 0.0, 1.0);
    // return passes_hdr ? vec4(tex.rgb, 1.0) : vec4(0.0, 0.0, 0.0, 1.0);

    // vec3 hdr = max(tex.rgb - hdr_threshold, vec3(0.0));
    // return vec4(hdr, 1.0);
    return max(tex - vec4(_hdr_threshold.x), vec4(0.0, 0.0, 0.0, 0.0));
}
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

vec4 sample_glow_pixel(sampler2D tex, vec2 uv) {
    float _hdr_threshold = 1.0; // Pixels with higher color than 1 will glow
    return max(texture(tex, uv) - _hdr_threshold, vec4(0.0));
}

vec4 gaussian_blur(sampler2D tex, vec2 uv, vec3 current_frag)
{
    // const float weight[5] = float[5] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    const float weight[5] = float[5] (0.06136, 0.24477, 0.38774, 0.24477, 0.06136);
    ivec2 texSize = textureSize(tex, 0);
    vec2 tex_offset = vec2(1.0) / vec2(float(texSize.x), float(texSize.y)); // gets size of single texel
    // vec3 result = texture(tex, uv).rgb * weight[3]; // current fragment's contribution
    // vec3 result = current_frag * weight[0]; // current fragment's contribution
    vec3 result = vec3(0.0);
    // for(int i = 1; i < 5; ++i)
    for(int x=-4/2; x < 4/2; ++x)
    {
        result += texture(tex, uv + vec2(tex_offset.x * float(x), 0.0)).rgb * weight[x];
        result += texture(tex, uv - vec2(tex_offset.x * float(x), 0.0)).rgb * weight[x];

        // for(int i = 1; i < 5; ++i)
        for(int y=-4/2; y < 4/2; ++y)
        {
            // if(y != 0)
            // {
                result += texture(tex, uv + vec2(0.0, tex_offset.y * float(y))).rgb * weight[y];
                result += texture(tex, uv - vec2(0.0, tex_offset.y * float(y))).rgb * weight[y];
            // }
        }
    }
    // return vec4(result * vec3(0.25), 1.0);
    return vec4(result, 1.0);
}

void fragment()
{
    vec4 hdr_pass = get_hdr_pass(texture(TEXTURE, UV), hdr_threshold);
    // COLOR = gaussian_blur(TEXTURE, UV, hdr_pass.rgb);
    // COLOR = hdr_pass;

    const float gamma = 2.2;
    vec4 hdrColor = sample_glow_pixel(TEXTURE, UV);      
    vec4 bloomColor = gaussian_blur(TEXTURE, UV, hdrColor.rgb);
    hdrColor += bloomColor; // additive blending
    // tone mapping
    vec4 result = vec4(1.0) - exp(-hdrColor * exposure);
    // also gamma correct while we're at it       
    result = pow(result, vec4(1.0 / gamma));
    // COLOR = hdrColor;
    // COLOR = sample_glow_pixel(TEXTURE, UV);

    // COLOR = gaussian_blur_pass(TEXTURE_PIXEL_SIZE, TEXTURE, UV, blur_samples) * blur_brightness;
    COLOR = enabled ? gaussian_blur_pass(TEXTURE_PIXEL_SIZE, TEXTURE, UV, blur_samples) * blur_brightness : texture(TEXTURE, UV);
}
