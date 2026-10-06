extends Control
class_name NightHud

signal camera_pressed

@onready var status: Label = $Status
@onready var hint: Label = $Hint
@onready var camera_button: Button = $Camera


func _ready() -> void:
	# Keyboard drives this through an input action; a focused button would also react to ui_accept (Space).
	camera_button.focus_mode = Control.FOCUS_NONE

	var left_door := _key_text("left_door")
	var right_door := _key_text("right_door")
	var left_light := _key_text("left_light")
	var right_light := _key_text("right_light")
	var monitor := _key_text("toggle_monitor")

	camera_button.text = "CAMERAS [%s]" % monitor
	hint.text = "%s/%s: doors   %s/%s: lights   %s: cameras" % [left_door, right_door, left_light, right_light, monitor]


func set_power(percent: int) -> void:
	status.text = "POWER %d%%" % percent


func show_power_out() -> void:
	status.text = "POWER 0% — DOORS OFF"


func _key_text(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			if event.physical_keycode != KEY_NONE:
				return event.as_text_physical_keycode()
			return event.as_text_keycode()
	return "?"


func _on_camera_pressed() -> void:
	camera_pressed.emit()
