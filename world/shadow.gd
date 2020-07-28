extends Sprite3D

export (float, 0, 10) var scale_min = 1
export (float, 0, 10) var scale_max = 2
export (float, 1, 10) var max_distance_from_ground = 2
export (float, 0, -2) var position_offset = -0.2

func update_shadow(origin_position: Vector3, distance_from_ground: float) -> void:
	# set shadow position
	translation = origin_position + Vector3(0, distance_from_ground - position_offset, 0)
	
	# set shadow scale
	var clamped_distance_from_ground = max(distance_from_ground * -1, max_distance_from_ground)
	var distance_weight = min(distance_from_ground * -1 / max_distance_from_ground, 1)
	var scale_multiplier = lerp(scale_max, scale_min, distance_weight)
	scale = Vector3(scale_multiplier, scale_multiplier, scale_multiplier)
