extends Node3D

const SpatialSinPan := preload("res://world/spatial_sin_pan.gd")

const SCALE_DISTANCE := 0.125
const DEFAULT_SCALE := Vector3.ONE * 0.775

@export var _reverse_direction := false

var _time := 0.0


func _ready():
	self.scale = DEFAULT_SCALE


func _process(p_delta: float):
	self._time += p_delta
	self.scale = get_animated_scale(self._time, self._reverse_direction)


func restart():
	self.scale = DEFAULT_SCALE
	self._time = 0.0


static func get_animated_scale(p_time: float, p_reverse_direction: bool) -> Vector3:
	var direction := 1 if p_reverse_direction else -1
	var offset_scale := (
		sin(p_time * SpatialSinPan.TRANSLATION_SPEED)
		* Vector3.ONE
		* SCALE_DISTANCE
		* direction
	)
	return DEFAULT_SCALE + offset_scale
