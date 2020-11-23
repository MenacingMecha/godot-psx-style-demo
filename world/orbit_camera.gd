extends Spatial

export (float, 0, 3) var speed = 1
export (bool) var rotate_camera = true

onready var default_y_rotation : float = rotation.y

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		rotate_camera = !rotate_camera
	if Input.is_action_just_pressed("reset_camera_position"):
		rotation.y = default_y_rotation
	rotate_y(1 * speed * delta * float(rotate_camera))
