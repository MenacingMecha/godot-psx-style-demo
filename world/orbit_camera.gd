extends Spatial

export (float, 0, 3) var speed = 1
export (bool) var rotate_camera = true

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		rotate_camera = !rotate_camera
	rotate_y(1 * speed * delta * float(rotate_camera))
