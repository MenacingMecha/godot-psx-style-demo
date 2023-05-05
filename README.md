# Godot PSX Style Demo

[Play demo in browser!](https://menacingmecha.itch.io/godot-psx-style-demo)

![Example Screenshot](./readme-assets/screenshot.png)

A collection of shaders and materials for Godot engine that aim to recreate the following aspects of the PS1 aesthetic:

- Vertex "snapping"
- "Wobbly" texures through affine texture mapping
- Limited color depth
- Hardware dithering to hide color banding
- Shiny chrome-like metallic surfaces
- Billboard sprites
- Fog to limit draw distance

Originally based on: https://github.com/marmitoTH/godot-psx-shaders

Floor texture (available under CC-0): https://stealthix.itch.io/rpg-nature-tileset

## Demo Controls

- Space: Toggle camera and object movement
- R: Reset scene

## Tips for best results

- Use very low poly models
    - Prefer smooth-shading over flat-shading wherever possible
    - Don't be afraid to include extra edge loops to smooth out texture distortion in your geometry! PS1 levels often had much higher polycounts than you might expect!
- Keep textures as low resolution as you can
    - Make sure filtering and mip-maps are both disabled
    - Rely on a mix of vertex colours and texture maps, instead of higher detailed texture maps wherever possible
    - Posterizing your textures with a depth of 15 or 16 before import goes a long way to making them feel more "PS1"
- Keep your internal resolution low
    - Common PS1 resolutions were 256×240, 320x240 and 512x240 ([Source](https://docs.google.com/spreadsheets/d/1UgysgrgqbiIlyHIiwCxVoWMu1bwgO2OBlDO1ORpsi78/edit?usp=sharing))
    - That being said, you can easily go widescreen by using a 16:9 resolution with similar height
- Use as basic of a lighting set up as you can get away with
    - Modern lighting techniques are a very easy way to break the illusion of appearing like early 3D!
    - Where possible, prefer to use white ambient light, with vertex colours on geometry to fake lighting
- Prefer additive blending to transparent blending

## Changes from v1.x

### Fog

Godot 4.0 changed how environmental fog worked, the key part being the removal of the "start distance" and "end distance" properties.
While a manual workaround could be implemented, there is work being done to restore this functionality in a later version.

### Switching from individual Shaders that does the same to the new Godot 4.0 Shader Preprocessor

Godot 4.0 adds a new feature called shader preprocessor, in a short and easy way to explain, it works like the parameters we can set on a Spatial Material. 
This are some examples:
- In LIT parameter you can set the shading_mode, also diffuse_mode and specular_mode.
- In CULL parameter you can set the cull_mode of the faces.
- In BLEND parameter you can set the blend_mode and so on.
You can read more about it [here](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shader_preprocessor.html).
In this way, we just define if a parameter is called on a Shader. It's all quite self-explanatory.
This example shows how can be done a vertex displacement shader, this could be very useful to make a water effect shader:
Here we declare our shader parameters that can be tweaked:
>#ifdef VERTEX_DISPLACEMENT
>uniform vec2 amplitude = vec2(0.01, 0.05);
>uniform vec2 frequency = vec2(3.0, 2.5);
>uniform vec2 time_factor = vec2(2.0, 3.0);
>uniform float alpha_value: hint_range(0.0, 1.0, 0.1) = 0.8;
>uniform float refraction = 0.05;
>uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest_mipmap;
>#endif
If the definition was called, we enable this float:
>#ifdef VERTEX_DISPLACEMENT
>float height(vec2 pos, float time) {
>	return (amplitude.x * sin(pos.x * frequency.x + time * time_factor.x)) + (amplitude.y * sin(pos.y * frequency.y + time * time_factor.y));
>}
>#endif
Then in the vertex() method we add this lines right before get the snapped position to grid
>#ifdef VERTEX_DISPLACEMENT
>	VERTEX.y += height(VERTEX.xz, TIME); // sample the height at the location of our vertex
>	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME) - height(VERTEX.xz + vec2(0.0, -0.2), TIME), 0.4));
>	BINORMAL = normalize(vec3(0.4, height(VERTEX.xz + vec2(0.2, 0.0), TIME) - height(VERTEX.xz + vec2(-0.2, 0.0), TIME ), 0.0));
>	NORMAL = cross(TANGENT, BINORMAL);
>#endif
And at the end of 
>#ifdef VERTEX_DISPLACEMENT
>	ALBEDO = texture(albedoTex, texture_uv).rgb * 0.5;
>	ALBEDO = (color_base * texture_color).rgb;
>	METALLIC = 0.0;
>	ROUGHNESS = 0.5;
>	NORMAL_MAP_DEPTH = 0.2;
>	
>	vec3 ref_normal = normalize( mix(NORMAL,TANGENT * NORMAL_MAP.x + BINORMAL * NORMAL_MAP.y + NORMAL * NORMAL_MAP.z,NORMAL_MAP_DEPTH) );
>	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
>	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs,ROUGHNESS * 2.0).rgb * (1.0 - ALPHA);
>	
>	ALBEDO *= ALPHA;
>	ALPHA = alpha_value;
>#endif

After all that is done create a new ".gdshader" resource and add this lines
>shader_type spatial;
>
>#define LIT diffuse_lambert, vertex_lighting
>#define CULL cull_disabled
>#define DEPTH depth_draw_always
>#define BLEND blend_add
>#define ALPHA_BLEND
>#define VERTEX_DISPLACEMENT
>
>#include "psx_base.gdshaderinc"

### Runtime options

In order to release working Godot 4 shaders as soon as possible, runtime options for the demo will be re-implemented at a later date.

## Games using these shaders (in some form)
- [Isle of Dreamers](https://menacingmecha.itch.io/isle-of-dreamers) - [MenacingMecha](https://menacingmecha.github.io/)
- [Inktober 2020 Demo Disc](https://menacingmecha.itch.io/inktober-2020-demo-disc) - [MenacingMecha](https://menacingmecha.github.io/)
- [Please Don't Feed the Creatures of the Deep](https://vaporshark.itch.io/please-dont-feed-the-creatures-of-the-deep) - [VaporShark](https://vaporshark.itch.io/)
- [Headlines from the Deep](https://menacingmecha.itch.io/headlines-from-the-deep) - [MenacingMecha](https://menacingmecha.github.io/)
- [Beetlebum](https://menacingmecha.itch.io/beetlebum) - [MenacingMecha](https://menacingmecha.github.io/)
- [P.O.S.S.U.M.](https://vaporshark.itch.io/possum) - [VaporShark](https://vaporshark.itch.io/)
- [The Deep Ones](https://bronxtaco.itch.io/the-deep-ones) - [bronxtaco](https://bronxtaco.itch.io/)

Please submit a PR (or send a message) if you have a title to add!
