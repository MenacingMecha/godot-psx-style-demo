extends Node

signal pause
signal reset

const PAUSE_ACTION := "ui_accept"
const RESET_ACTION := "reset_camera_position"
const CAN_PAUSE_AND_RESET_NODE_GROUP := "can_pause_and_reset"

var _is_paused := false setget _set_is_paused


func _ready():
	for node in get_tree().get_nodes_in_group(CAN_PAUSE_AND_RESET_NODE_GROUP):
		connect("pause", node, "set_process")
		assert(node.has_method("on_reset"))
		connect("reset", node, "on_reset")


func _unhandled_input(event: InputEvent):
	# TODO: change to `is_action_released()` when all relevant objects use this
	if event.is_action_pressed(PAUSE_ACTION):
		self._is_paused = !self._is_paused

	elif event.is_action_pressed(RESET_ACTION):
		emit_signal("reset")

	get_tree().set_input_as_handled()


func _set_is_paused(p_paused: bool):
	_is_paused = p_paused
	emit_signal("pause", !p_paused)
