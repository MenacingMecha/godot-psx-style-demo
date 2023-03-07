extends Spatial

const TRANSLATION_DISTANCE := 1.0
const TRANSLATION_SPEED := 1.0
const ROTATION_SPEED := 1.0

export var _shadow_path: NodePath
export var _reverse_direction := false

var _time: float = 0

onready var _default_transform: Transform = get_transform()
onready var _shadow := get_node(self._shadow_path)


func _process(p_delta: float):
	self._time += p_delta
	self.transform = get_animated_transform(
		self._default_transform, self._time, self._reverse_direction
	)

	# update shadow
	var space_state = get_world().direct_space_state
	# TODO: Magic number
	var result = space_state.intersect_ray(
		self.translation, self.translation + Vector3(0, -100, 00)
	)
	if result:
		if result.collider.name == "FloorBody":
			var distance_from_ground = result.position - translation
			self._shadow.update_shadow(translation, distance_from_ground.y)


func on_reset():
	set_transform(self._default_transform)
	self._time = 0


static func get_animated_transform(
	p_default_transform: Transform, p_time: float, p_reverse_direction: bool
) -> Transform:
	var rotation = Vector3.ONE * p_time * ROTATION_SPEED
	var translation_direction := -1 if p_reverse_direction else 1
	var y_pos := sin(p_time * TRANSLATION_SPEED) * TRANSLATION_DISTANCE * translation_direction
	var offset_transform := Transform(Basis(rotation), Vector3.UP * y_pos)
	return p_default_transform * offset_transform
