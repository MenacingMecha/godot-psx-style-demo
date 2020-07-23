shader_type canvas_item;

uniform float rgb_intensity = 1;
uniform float scanline_intensity = 0.25;

void fragment()
{
    // Get pos relative to 0-1 screen space
    vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE);
    
    // Map texture to 0-1 space
    vec4 texColor = texture(TEXTURE,uv);
    
    // Default lcd colour (affects brightness)
    float pb = 0.4;
    vec4 lcdColor = vec4(pb,pb,pb,1.0);
    
    // Change every 1st, 2nd, and 3rd vertical strip to RGB respectively
    int px = int(mod(FRAGCOORD.x,3.0));
	if (px == 1) lcdColor.r = 1.0;
    else if (px == 2) lcdColor.g = 1.0;
    else lcdColor.b = 1.0;
    
    // Darken every 3rd horizontal strip for scanline
    float sclV = 0.25;
    if (int(mod(FRAGCOORD.y,3.0)) == 0) lcdColor.rgb = vec3(scanline_intensity);
    
    COLOR = texColor * mix(vec4(1), lcdColor, rgb_intensity);
}