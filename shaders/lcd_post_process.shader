shader_type canvas_item;

uniform bool enabled = true;
uniform vec2 blur_scale = vec2(0.1, 0.0);
uniform float blur_samples = 50.0;
uniform float glow_strength = 1.5;
uniform float lcd_opacity = 0.5;
uniform int scanline_gap = 5;
uniform float brightness = 1.0;

const float PI2 = 6.283185307179586476925286766559;

// http://theorangeduck.com/page/avoiding-shader-conditionals
float when_eq(int x, int y)
{
    return 1.0 - abs(sign(float(x) - float(y)));
}

vec4 lcdColor(int pos_x, int pos_y)
{
    vec4 lcdColor = vec4(1);
    // Change every 1st, 2nd, and 3rd vertical strip to RGB respectively
	// if (px == 1) lcdColor.r = 1.0;
    // else if (px == 2) lcdColor.g = 1.0;
    // else lcdColor.b = 1.0;
    lcdColor.r = lcdColor.r * when_eq(pos_x, 0);
    lcdColor.g = lcdColor.g * when_eq(pos_x, 1);
    lcdColor.b = lcdColor.b * when_eq(pos_x, 2);
    
    // Darken every 3rd horizontal strip for scanline
    // if (int(mod(FRAGCOORD.y,3.0)) == 0) lcdColor.rgb = vec3(0);
    lcdColor.rgb = lcdColor.rgb * vec3(1.0 - when_eq(pos_y, 0));

    return lcdColor;
}

float gaussian(float x)
{
	float x_squared = x*x;
	float width = 1.0 / sqrt(PI2 * blur_samples);

	return width * exp((x_squared / (2.0 * blur_samples)) * -1.0);
}

void fragment()
{
    vec4 tex = texture(TEXTURE,UV);
    if (enabled)
    {
        // TODO: move calculating the blur to a seperate method
        float weight = 0.0;
        float total_weight = 0.0;
        vec2 scale_horiz = TEXTURE_PIXEL_SIZE * vec2(blur_scale.x, 0.0);
        vec4 color_horiz = vec4(0.0);
        
        for(int i=-int(blur_samples)/2; i < int(blur_samples)/2; ++i) {
            weight = gaussian(float(i));
            color_horiz += texture(TEXTURE, UV + scale_horiz * vec2(float(i))) * weight;
            total_weight += weight;
        }

        weight = 0.0;
        total_weight = 0.0;
        vec2 scale_vert = TEXTURE_PIXEL_SIZE * vec2(0.0, blur_scale.y);
        vec4 color_vert = vec4(0.0);

        for(int i=-int(blur_samples)/2; i < int(blur_samples)/2; ++i) {
            weight = gaussian(float(i));
            color_vert += texture(TEXTURE, UV + scale_vert * vec2(float(i))) * weight;
            total_weight += weight;
        }

        vec4 blur_horiz = color_horiz / total_weight;
        vec4 blur_vert = color_vert / total_weight;
        vec4 blur = mix(color_horiz, color_vert, 0.5);

        int pos_x = int(mod(FRAGCOORD.x, 3.0));
        int pos_y = int(mod(FRAGCOORD.y, float(scanline_gap)));
        vec4 lcd_overlay_tex = lcdColor(pos_x, pos_y);

        // COLOR = (blur * vec4(glow_strength)) * mix(vec4(1), lcd_overlay_tex, lcd_opacity);

        // vec4 hdr_pass = get_hdr_pass(tex, hdr_threshold);
        // COLOR = gaussian_blur(TEXTURE, UV, hdr_pass.rgb);
        // COLOR = hdr_pass;

        COLOR = mix(blur, blur * lcd_overlay_tex, lcd_opacity);
    }
    else
    {
        COLOR = tex;
    }
}