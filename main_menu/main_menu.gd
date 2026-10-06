extends Control

const CONTROLS: Array = [
	["left_door", "Toggle left door"],
	["right_door", "Toggle right door"],
	["left_light", "Toggle left vent light"],
	["right_light", "Toggle right vent light"],
	["toggle_monitor", "Open/close monitor"],
]

@onready var night_buttons: Control = %NightButtons
@onready var controls_button: Button = %ControlsButton
@onready var controls_popup: Control = %ControlsPopup
@onready var controls_rows: GridContainer = %Rows
@onready var ok_button: Button = %OkButton


func _ready() -> void:
	for i in night_buttons.get_child_count():
		var button := night_buttons.get_child(i) as Button
		button.pressed.connect(start_night.bind(i + 1))

	_build_controls_rows()
	controls_button.pressed.connect(controls_popup.show)
	ok_button.pressed.connect(controls_popup.hide)


func _unhandled_input(event: InputEvent) -> void:
	if controls_popup.visible and event.is_action_pressed("ui_cancel"):
		controls_popup.hide()
		get_viewport().set_input_as_handled()


func start_night(night: int) -> void:
	Global.current_night = night
	get_tree().change_scene_to_file("res://night/night.tscn")


func _build_controls_rows() -> void:
	var chip_style := _make_key_chip_style()
	for entry: Array in CONTROLS:
		var key_label := Label.new()
		key_label.text = _key_text(entry[0])
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 24)
		key_label.add_theme_color_override("font_color", Color(1, 0.85, 0.8))
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", chip_style)
		chip.custom_minimum_size = Vector2(90, 0)
		chip.add_child(key_label)
		controls_rows.add_child(chip)

		var desc := Label.new()
		desc.text = entry[1]
		desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 24)
		desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
		controls_rows.add_child(desc)


func _make_key_chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.05, 0.06)
	style.set_border_width_all(1)
	style.border_color = Color(0.7, 0.1, 0.1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style


func _key_text(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			if event.physical_keycode != KEY_NONE:
				return event.as_text_physical_keycode()
			return event.as_text_keycode()
	return "?"
