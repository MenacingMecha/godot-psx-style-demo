shader_type spatial; 
render_mode skip_vertex_transform, diffuse_lambert_wrap, vertex_lighting;

uniform vec4 color : hint_color;
uniform sampler2D albedoTex : hint_albedo;
uniform sampler2D reflectionTex : hint_albedo;
uniform samplerCube cubemap;
uniform float cubemap_opacity;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
uniform float vertex_resolution = 128;
uniform float cull_distance = 100;
uniform bool dither_enabled = true;
uniform float dither_resolution = 1;
uniform float dither_intensity = 0.1;
uniform int color_depth = 15;
uniform vec3 dither_luminosity = vec3(.299, 0.587, 0.114);

varying vec4 vertex_coordinates;

varying vec2 shiftedPosition;
varying vec2 width_height;
varying vec3 cubemap_UV;

// https://gist.github.com/jw-0/9486042b5343c1f4f90451de7f4ef86e
float dither4x4(vec2 position, float brightness)
{
	float x = floor(mod(position.x, 4));
	float y = floor(mod(position.y, 4));
	float index = floor(x + y * 4.0);
	float limit = 0.0;

	if(x < 8.0)
	{
		if (index == float(0))  { limit = 0.0625; }
		else if (index == float(1))  { limit = 0.5625; }
		else if (index == float(2))  { limit = 0.1875; }
		else if (index == float(3))  { limit = 0.6875; }
		else if (index == float(4))  { limit = 0.8125; }
		else if (index == float(5))  { limit = 0.3125; }
		else if (index == float(6))  { limit = 0.9375; }
		else if (index == float(7))  { limit = 0.4375; }
		else if (index == float(8))  { limit = 0.25;   }
		else if (index == float(9))  { limit = 0.75;   }
		else if (index == float(10)) { limit = 0.125;  }
		else if (index == float(11)) { limit = 0.625;  }
		else if (index == float(12)) { limit = 1.0;    }
		else if (index == float(13)) { limit = 0.5;    }
		else if (index == float(14)) { limit = 0.875;  }
		else if (index == float(15)) { limit = 0.375;  } 
	}
	return brightness < limit ? 1.0 : 0.0;
}

// https://stackoverflow.com/a/42470600
vec4 band_color(vec4 _color, int num_of_colors)
{
	vec4 num_of_colors_vec = vec4(float(num_of_colors));
	return floor(_color * num_of_colors_vec) / num_of_colors_vec;
}

void vertex()
{
	UV = UV * uv_scale + uv_offset;

	// affine texture mapping & vertex snapping
	// https://github.com/marmitoTH/godot-psx-shaders/
	float vertex_distance = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float vPos_w = (PROJECTION_MATRIX * vec4(VERTEX, 1.0)).w;
	VERTEX.xy = vPos_w * floor(vertex_resolution * VERTEX.xy / vPos_w) / vertex_resolution;
	vertex_coordinates = vec4(UV * VERTEX.z, VERTEX.z, .0);

	VERTEX = vertex_distance > cull_distance ? vec3(.0) : VERTEX;

	// define cubemap UV
	// https://godotforums.org/discussion/15406/cubemap-reflections-cubic-environment-mapping
	vec4 invcamx = INV_CAMERA_MATRIX[0];
	vec4 invcamy = INV_CAMERA_MATRIX[1];
	vec4 invcamz = INV_CAMERA_MATRIX[2];
	vec4 invcamw = INV_CAMERA_MATRIX[3];

	vec3 CameraPosition = -invcamw.xyz * mat3( invcamx.xyz, invcamy.xyz, invcamz.xyz );

	vec3 vertexW = (WORLD_MATRIX * vec4(VERTEX, 0.0)).xyz; 		//vertex from model to world space
	vec3 N = normalize(WORLD_MATRIX * vec4(NORMAL.x, NORMAL.y, NORMAL.z, 0.0)).xyz;	//normal from model space to world space
	vec3 I = normalize(vertexW - CameraPosition);				//incident vector (from camera to vertex)
	vec3 R = reflect(I, N);					//reflection vector (from vertex to cube map)
	R.z *= -1.0;
	cubemap_UV = R;
}

void fragment()
{
	vec4 banded_color = band_color(color, color_depth);
	vec4 cubemap_tex = texture(cubemap, cubemap_UV);
	vec4 metal_surface = banded_color * cubemap_tex;
	if (dither_enabled)
	{
		float luma = dot(color.rgb, dither_luminosity);
		vec4 checker = vec4(vec3(dither4x4(vec2(dither_resolution) * FRAGCOORD.xy, luma)), 1);
		metal_surface = mix(metal_surface, metal_surface * checker, dither_intensity);
	}
	ALBEDO = metal_surface.rgb;
}