#pragma disable_preprocessor
shader_type canvas_item;

uniform bool enabled = true;
uniform float lcd_opacity = 0.5;
uniform int scanline_gap = 5;

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

void fragment()
{
    vec4 tex = texture(TEXTURE,UV);
    int pos_x = int(mod(FRAGCOORD.x, 3.0));
    int pos_y = int(mod(FRAGCOORD.y, float(scanline_gap)));
    vec4 lcd_overlay_tex = lcdColor(pos_x, pos_y);
    COLOR = enabled ? mix(tex, tex * lcd_overlay_tex, lcd_opacity) : tex;
}
