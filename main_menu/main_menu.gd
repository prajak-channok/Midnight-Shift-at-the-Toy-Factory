extends Control

@onready var night_buttons: Control = %NightButtons
@onready var fullscreen_button: TextureButton = $FullScreenButton
@onready var controls_button: Button = %ControlsButton
@onready var controls_popup: Control = %ControlsPopup
@onready var ok_button: Button = %OkButton


func _ready() -> void:
	for i in night_buttons.get_child_count():
		var button := night_buttons.get_child(i) as Button
		button.pressed.connect(start_night.bind(i + 1))
		if not SaveManager.is_night_unlocked(i + 1):
			button.disabled = true

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
