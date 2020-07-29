# Godot PSX Style Demo

[WebGL demo](https://menacingmecha.itch.io/godot-psx-style-demo)

Collection of shaders and materials to recreate the following aspects of the PS1 aesthetic:

- Vertex snapping
- Affine texture mapping
- Hardware dithering
- Shiny metallic surfaces based on cubemap reflections
- Sprite-based shadows
- Fog to limit draw distance
- LCD post-processing shader to emulate old displays

## Demo Controls

- 1: Toggle post-process passes
- 2: Toggle dithering
- Space: Toggle camera and object movement

## For best results when using

- Use low poly models
- Low resolution textures (with filtering and mip-maps disabled)
- Use a low internal resolution with a higher test resolution (or higher resolution with viewport scaling enabled if using post-processing)
- Use only ambient world lighting with fog

Originally based on: https://github.com/marmitoTH/godot-psx-shaders

Floor texture (availible under CC-0): https://stealthix.itch.io/rpg-nature-tileset
