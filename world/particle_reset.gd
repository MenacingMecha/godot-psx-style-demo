extends Particles

func _physics_process(delta):
	if Input.is_action_just_pressed("reset_camera_position"):
		restart()
