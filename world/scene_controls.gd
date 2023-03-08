extends Node

signal pause
signal reset

const PAUSE_ACTION := "ui_accept"
const RESET_ACTION := "reset_camera_position"

var _is_paused := false setget _set_is_paused


func _ready():
	for node in get_tree().get_nodes_in_group("can_pause"):
		connect("pause", node, "set_process")

	for node in get_tree().get_nodes_in_group("can_restart"):
		assert(node.has_method("restart"))
		connect("reset", node, "restart")


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed(PAUSE_ACTION):
		self._is_paused = !self._is_paused

	elif event.is_action_pressed(RESET_ACTION):
		emit_signal("reset")

	get_tree().set_input_as_handled()


func _set_is_paused(p_paused: bool):
	_is_paused = p_paused
	emit_signal("pause", !p_paused)
