shader_type spatial; 
render_mode skip_vertex_transform, diffuse_lambert_wrap, specular_phong, blend_mix, vertex_lighting, cull_disabled;

uniform vec4 color : hint_color;
uniform sampler2D albedoTex : hint_albedo;
uniform float specular_intensity : hint_range(0, 1);
uniform float resolution = 256;
uniform float cull_distance = 5;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
uniform vec2 dither_resolution = vec2(32, 32);
uniform float dither_intensity = 0.025;

varying vec4 vertex_coordinates;

float dither4x4(vec2 position, float brightness)
{
	float x = floor(mod(position.x, 4));
	float y = floor(mod(position.y, 4));
	float index = floor(x + y * 4.0);
	float limit = 0.0;
		
	if(x < 8.0)
	{
		if (index == float(0))  { limit = 0.0625; }
		if (index == float(1))  { limit = 0.5625; }
		if (index == float(2))  { limit = 0.1875; }
		if (index == float(3))  { limit = 0.6875; }
		if (index == float(4))  { limit = 0.8125; }
		if (index == float(5))  { limit = 0.3125; }
		if (index == float(6))  { limit = 0.9375; }
		if (index == float(7))  { limit = 0.4375; }
		if (index == float(8))  { limit = 0.25;   }
		if (index == float(9))  { limit = 0.75;   }
		if (index == float(10)) { limit = 0.125;  }
		if (index == float(11)) { limit = 0.625;  }
		if (index == float(12)) { limit = 1.0;    }
		if (index == float(13)) { limit = 0.5;    }
		if (index == float(14)) { limit = 0.875;  }
		if (index == float(15)) { limit = 0.375;  } 
	}
	float _out = 1.0;
	if (brightness < limit) { _out = 0.0; }
	return _out;
}

void vertex() {
	UV = UV * uv_scale + uv_offset;
	
	float vertex_distance = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)));
	
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float vPos_w = (PROJECTION_MATRIX * vec4(VERTEX, 1.0)).w;
	VERTEX.xy = vPos_w * floor(resolution * VERTEX.xy / vPos_w) / resolution;
	vertex_coordinates = vec4(UV * VERTEX.z, VERTEX.z, .0);
	
	if (vertex_distance > cull_distance)
		VERTEX = vec3(.0);
}

void fragment() {
	vec4 tex = texture(albedoTex, vertex_coordinates.xy / vertex_coordinates.z);
	//ALBEDO = tex.rgb * color.rgb;
	ALPHA = color.a;
	SPECULAR = specular_intensity;
	
	vec3 luminosity = vec3(.299, 0.587, 0.114);
	float luma = dot(tex.rgb, luminosity);
	vec4 dither = tex*color*vec4(vec3(dither4x4(dither_resolution*vertex_coordinates.xy / vertex_coordinates.z, luma)), 1);
	ALBEDO = mix(tex.rgb * color.rgb, dither.rgb, dither_intensity);
}