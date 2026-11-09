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
@onready var exit_button: Button = %ExitButton

@onready var hover_player: AudioStreamPlayer = %HoverPlayer
@onready var click_player: AudioStreamPlayer = %ClickPlayer
@onready var start_player: AudioStreamPlayer = %StartPlayer
@onready var ambience_player: AudioStreamPlayer = %AmbiencePlayer

const NIGHT_SCENE := "res://night/night.tscn"

var _starting := false


func _ready() -> void:
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
	get_window().size_changed.connect(_refresh_settings_labels)
	_refresh_settings_labels()

	exit_button.pressed.connect(get_tree().quit)

	_setup_button_sounds()


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
	if _starting:
		return
	_starting = true
	Global.current_night = night
	create_tween().tween_property(ambience_player, "volume_db", -60.0, 0.35)
	if start_player.stream != null:
		await get_tree().create_timer(0.35).timeout
	SceneLoader.change_scene(NIGHT_SCENE)


func _on_mute_pressed() -> void:
	Global.toggle_mute()
	_refresh_settings_labels()


func _refresh_settings_labels() -> void:
	fullscreen_button.text = "EXIT FULLSCREEN" if Global.is_fullscreen() else "FULLSCREEN"
	mute_button.text = "SOUND: OFF" if Global.is_muted() else "SOUND: ON"


func _setup_button_sounds() -> void:
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		button.mouse_entered.connect(_on_button_hover.bind(button))
		if button.get_parent() == night_buttons:
			button.pressed.connect(_play.bind(start_player))
		else:
			button.pressed.connect(_play.bind(click_player))


func _on_button_hover(button: Button) -> void:
	if not button.disabled:
		_play(hover_player)


func _play(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null:
		player.play()
