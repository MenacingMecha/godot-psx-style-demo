extends Spatial

export (NodePath) var shadow_path
export (float, 0, 100) var rotation_speed = 50
export (float, -2, 2) var translation_distance = 0.5
export (float, 0, 2) var translation_speed = 1
export (bool) var should_update = true

var time: float = 0
var default_y: float = 0
var custom_rotation = Vector3.ONE
var shadow

onready var default_transform : Transform = get_transform()

func _ready():
	default_y = translation.y
	shadow = get_node(shadow_path)

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		should_update = !should_update

	if Input.is_action_just_pressed("reset_camera_position"):
		set_transform(default_transform)
		custom_rotation = Vector3.ONE
		time = 0
		
	if should_update:
		# funky movement
		time += delta
		custom_rotation += Vector3.ONE * delta * rotation_speed
		translation.y = default_y - sin(time * translation_speed) * translation_distance
		set_rotation_degrees(custom_rotation)
		
		# update shadow
		var space_state = get_world().direct_space_state
		# TODO: Magic number
		var result = space_state.intersect_ray(translation, translation + Vector3(0, -100, 00))
		if result:
			if result.collider.name == "FloorBody":
				var distance_from_ground = result.position - translation
				shadow.update_shadow(translation, distance_from_ground.y)


