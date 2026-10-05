extends Control
class_name NightHud

signal left_door_pressed
signal right_door_pressed
signal left_light_pressed
signal right_light_pressed
signal camera_pressed

@onready var status: Label = $Status
@onready var hint: Label = $Hint
@onready var left_door_button: Button = $LeftDoor
@onready var right_door_button: Button = $RightDoor
@onready var left_light_button: Button = $LeftLight
@onready var right_light_button: Button = $RightLight
@onready var camera_button: Button = $Camera


func _ready() -> void:
	# Keyboard drives these through input actions; a focused button would also react to ui_accept (Space).
	for button: Button in [left_door_button, right_door_button, left_light_button, right_light_button, camera_button]:
		button.focus_mode = Control.FOCUS_NONE

	var left_door := _key_text("left_door")
	var right_door := _key_text("right_door")
	var left_light := _key_text("left_light")
	var right_light := _key_text("right_light")
	var monitor := _key_text("toggle_monitor")

	left_door_button.text = "LEFT DOOR [%s]" % left_door
	right_door_button.text = "RIGHT DOOR [%s]" % right_door
	left_light_button.text = "LEFT LIGHT [%s]" % left_light
	right_light_button.text = "RIGHT LIGHT [%s]" % right_light
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


func _on_left_door_pressed() -> void:
	left_door_pressed.emit()


func _on_right_door_pressed() -> void:
	right_door_pressed.emit()


func _on_left_light_pressed() -> void:
	left_light_pressed.emit()


func _on_right_light_pressed() -> void:
	right_light_pressed.emit()


func _on_camera_pressed() -> void:
	camera_pressed.emit()
