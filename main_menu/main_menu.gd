extends Control

@onready var night_buttons: Control = %NightButtons
@onready var controls_button: Button = %ControlsButton
@onready var controls_popup: Control = %ControlsPopup
@onready var ok_button: Button = %OkButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_popup: Control = %SettingsPopup
@onready var fullscreen_button: Button = %FullScreenButton
@onready var mute_button: Button = %MuteButton
@onready var settings_close_button: Button = %SettingsCloseButton
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	# The music follows the Master bus, so the SOUND ON/OFF button (Global.toggle_mute) mutes it too.
	(music.stream as AudioStreamOggVorbis).loop = true
	music.play()

	for i in night_buttons.get_child_count():
		var button := night_buttons.get_child(i) as Button
		button.pressed.connect(start_night.bind(i + 1))
		if not SaveManager.is_night_unlocked(i + 1):
			button.disabled = true

	controls_button.pressed.connect(controls_popup.show)
	ok_button.pressed.connect(controls_popup.hide)

	settings_button.pressed.connect(settings_popup.show)
	settings_close_button.pressed.connect(settings_popup.hide)
	fullscreen_button.pressed.connect(Global.toggle_fullscreen)
	mute_button.pressed.connect(_on_mute_pressed)
	# Fullscreen can also be toggled with the key, and the web build enters it asynchronously.
	get_window().size_changed.connect(_refresh_settings_labels)
	_refresh_settings_labels()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if controls_popup.visible:
		controls_popup.hide()
		get_viewport().set_input_as_handled()
	elif settings_popup.visible:
		settings_popup.hide()
		get_viewport().set_input_as_handled()


func start_night(night: int) -> void:
	Global.current_night = night
	get_tree().change_scene_to_file("res://night/night.tscn")


func _on_mute_pressed() -> void:
	Global.toggle_mute()
	_refresh_settings_labels()


func _refresh_settings_labels() -> void:
	fullscreen_button.text = "EXIT FULLSCREEN" if Global.is_fullscreen() else "FULLSCREEN"
	mute_button.text = "SOUND: OFF" if Global.is_muted() else "SOUND: ON"
