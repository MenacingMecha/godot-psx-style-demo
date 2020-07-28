extends Node

export (Array, Material) var materials_with_dithering

func _process(delta):
	if Input.is_action_just_pressed("kb_2"):
		for material in materials_with_dithering:
			material.set_shader_param("dither_enabled", !material.get_shader_param("dither_enabled"))
