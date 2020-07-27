extends ViewportContainer

export (String) var toggle_action_name;

func _ready():
	material = get_material()

func _process(delta):
	if Input.is_action_just_pressed(toggle_action_name):
		material.set_shader_param("enabled", !material.get_shader_param("enabled"))
