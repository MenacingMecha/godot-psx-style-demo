extends Spatial

export (float, 0, 3) var speed = 1

func _process(delta):
	rotate_y(1 * speed * delta)
