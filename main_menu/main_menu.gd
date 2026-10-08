extends Control

## [action or literal key label, description]
const CONTROLS: Array = [
	["left_door", "Close / open the LEFT door"],
	["right_door", "Close / open the RIGHT door"],
	["left_light", "Left vent light on / off"],
	["right_light", "Right vent light on / off"],
	["toggle_monitor", "Raise / lower the camera monitor"],
	["flashlight", "Hold to flash the camera you are watching"],
	["MOUSE", "Move to the screen edge to look around"],
]

@onready var night_buttons: Control = %NightButtons
@onready var fullscreen_button: TextureButton = $FullScreenButton
@onready var controls_button: Button = %ControlsButton
@onready var controls_popup: Control = %ControlsPopup
@onready var controls_rows: GridContainer = %Rows
@onready var ok_button: Button = %OkButton


func _ready() -> void:
	for i in night_buttons.get_child_count():
		var button := night_buttons.get_child(i) as Button
		button.pressed.connect(start_night.bind(i + 1))
		if not SaveManager.is_night_unlocked(i + 1):
			button.disabled = true

	_build_controls_rows()
	controls_button.pressed.connect(controls_popup.show)
	ok_button.pressed.connect(controls_popup.hide)
	fullscreen_button.pressed.connect(Global.toggle_fullscreen)


func _unhandled_input(event: InputEvent) -> void:
	if controls_popup.visible and event.is_action_pressed("ui_cancel"):
		controls_popup.hide()
		get_viewport().set_input_as_handled()


func start_night(night: int) -> void:
	Global.current_night = night
	get_tree().change_scene_to_file("res://night/night.tscn")


func _build_controls_rows() -> void:
	for entry: Array in CONTROLS:
		var key_label := Label.new()
		key_label.text = _key_text(entry[0]).to_upper()
		key_label.theme_type_variation = &"KeyLabel"
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(110, 0)
		chip.add_child(key_label)
		controls_rows.add_child(chip)

		var desc := Label.new()
		desc.text = entry[1]
		desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		controls_rows.add_child(desc)


func _key_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return action
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			if event.physical_keycode != KEY_NONE:
				return event.as_text_physical_keycode()
			return event.as_text_keycode()
	return "?"
