shader_type spatial;

#define LIT diffuse_lambert, vertex_lighting
#define CULL cull_disabled
#define DEPTH depth_prepass_alpha
#define BLEND blend_mix
#define ALPHA_SCISSOR

#include "psx_base.gdshaderinc"
