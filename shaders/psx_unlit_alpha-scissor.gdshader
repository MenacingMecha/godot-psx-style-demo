shader_type spatial;

#define LIT unshaded
#define CULL cull_disabled
#define DEPTH depth_prepass_alpha
#define BLEND blend_mix
#define ALPHA_SCISSOR

#include "psx_base.gdshaderinc"
