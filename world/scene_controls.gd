extends Node

signal pause
signal reset

const PAUSE_ACTION := "ui_accept"
const RESET_ACTION := "reset_camera_position"

var _is_paused := false :
	set (value):
		_is_paused = value
		emit_signal("pause", !value)

@onready var _viewport := get_viewport()


func _ready():
	for node in get_tree().get_nodes_in_group("can_pause"):
		pause.connect(node.set_process.bind())

	for node in get_tree().get_nodes_in_group("can_restart"):
		assert(node.has_method("restart"))
		reset.connect(node.restart.bind())


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed(PAUSE_ACTION):
		self._is_paused = !self._is_paused

	elif event.is_action_pressed(RESET_ACTION):
		emit_signal("reset")

	self._viewport.set_input_as_handled()

