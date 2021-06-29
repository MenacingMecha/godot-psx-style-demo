# Godot PSX Style Demo

[Play demo in browser!](https://menacingmecha.itch.io/godot-psx-style-demo)

![Preview GIF](./readme-assets/preview.gif)

![Example Screenshot](./readme-assets/screenshot.png)

A collection of shaders and materials for Godot engine that aim to recreate the following aspects of the PS1 aesthetic:

- Vertex "snapping"
- "Wobbly" texures through affine texture mapping
- Limited color depth
- Hardware dithering to hide color banding
- Shiny chrome-like metallic surfaces
- Billboard sprites
- Fog to limit draw distance
- LCD post-processing shader to emulate old displays

## Demo Controls

- Space: Toggle camera and object movement
- R: Reset scene

## Tips for best results

- Use low poly models
- Keep textures as low resolution as you can
    - Make sure filtering and mip-maps are both disabled
    - Use vertex colours instead of texture maps wherever possible
- Keep your internal resolution low
    - Standard PS1 resolution was 256×224, but you can easily go widescreen by using a 16:9 resolution with similar height
- Use as basic of a lighting set up as you can get away with

Originally based on: https://github.com/marmitoTH/godot-psx-shaders

Floor texture (available under CC-0): https://stealthix.itch.io/rpg-nature-tileset
