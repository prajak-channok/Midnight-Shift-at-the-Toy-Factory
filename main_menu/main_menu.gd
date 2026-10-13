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

const NIGHT_SCENE := "res://night/night.tscn"
const SOUND_HOVER := "res://main_menu/sounds/ui_hover.wav"
const SOUND_CLICK := "res://main_menu/sounds/ui_click.wav"
const SOUND_START := "res://main_menu/sounds/ui_start.wav"
const SOUND_AMBIENCE := "res://main_menu/sounds/menu_ambience.wav"

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer
var _start_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _starting := false

## Loudness of the background ambience (more negative = quieter).
const AMBIENCE_VOLUME_DB := 5


func _ready() -> void:
	SaveManager.complete_night(2)
	SaveManager.complete_night(3)
	SaveManager.complete_night(4)
	SaveManager.complete_night(5)
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

	exit_button.pressed.connect(get_tree().quit)

	_setup_button_sounds()
	_setup_ambience()


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
	# Fade the factory ambience out while the start sound plays, then change the scene.
	create_tween().tween_property(_ambience_player, "volume_db", -60.0, 0.35)
	if _start_player.stream != null:
		await get_tree().create_timer(0.35).timeout
	await _load_and_change_scene(NIGHT_SCENE)


## Shows the loading overlay, then loads the scene in the background so the overlay keeps animating.
func _load_and_change_scene(path: String) -> void:
	add_child(LoadingOverlay.new())
	# Let the overlay get drawn before any (possibly blocking) loading begins.
	await get_tree().process_frame
	await get_tree().process_frame

	if ResourceLoader.load_threaded_request(path) != OK:
		get_tree().change_scene_to_file(path)
		return
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	var scene := ResourceLoader.load_threaded_get(path) as PackedScene
	if scene == null:
		get_tree().change_scene_to_file(path)
		return
	get_tree().change_scene_to_packed(scene)


func _on_mute_pressed() -> void:
	Global.toggle_mute()
	_refresh_settings_labels()


func _refresh_settings_labels() -> void:
	fullscreen_button.text = "EXIT FULLSCREEN" if Global.is_fullscreen() else "FULLSCREEN"
	mute_button.text = "SOUND: OFF" if Global.is_muted() else "SOUND: ON"


# ---------- button sounds ----------

func _setup_button_sounds() -> void:
	_hover_player = _make_player(SOUND_HOVER, -10.0)
	_click_player = _make_player(SOUND_CLICK, -4.0)
	_start_player = _make_player(SOUND_START, -2.0)
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		button.mouse_entered.connect(_on_button_hover.bind(button))
		if button.get_parent() == night_buttons:
			button.pressed.connect(_play.bind(_start_player))  # night buttons get the "start" sound
		else:
			button.pressed.connect(_play.bind(_click_player))


func _make_player(path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists(path):
		player.stream = load(path)
	else:
		push_warning("Menu sound missing: %s" % path)
	player.volume_db = volume_db
	add_child(player)
	return player


func _on_button_hover(button: Button) -> void:
	if not button.disabled:
		_play(_hover_player)


func _play(player: AudioStreamPlayer) -> void:
	if player.stream != null:
		player.play()


# ---------- background ambience ----------

func _setup_ambience() -> void:
	_ambience_player = _make_player(SOUND_AMBIENCE, AMBIENCE_VOLUME_DB)
	if _ambience_player.stream != null:
		_ambience_player.play()
