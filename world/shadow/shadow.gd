extends Spatial

const SCALE_MIN := 0.5
const SCALE_MAX := 1.4

export(float, 1, 10) var max_distance_from_ground = 2
export(float, 0, -2) var position_offset = -0.2


func update_shadow(origin_position: Vector3, distance_from_ground: float) -> void:
	# set shadow position
#	translation = origin_position + Vector3(0, distance_from_ground - position_offset, 0)

	# set shadow scale
	var clamped_distance_from_ground = max(distance_from_ground * -1, max_distance_from_ground)
	var distance_weight = min(distance_from_ground * -1 / max_distance_from_ground, 1)
	var scale_multiplier = lerp(SCALE_MAX, SCALE_MIN, distance_weight)
	scale = Vector3(scale_multiplier, scale_multiplier, scale_multiplier)
