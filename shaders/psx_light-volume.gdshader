shader_type spatial;

#define LIT diffuse_lambert, vertex_lighting
#define CULL cull_disabled
#define DEPTH depth_draw_opaque
#define BLEND blend_add
#define NO_TEXTURE
#define LIGHT_VOLUME

#include "psx_base.gdshaderinc"
