extends Node
class_name CameraManager
## Camera Manager node
##
## This node manages a bunch of Camera3D nodes and keeps in its scene a Camera UI
## that contains a bunch of camera buttons to allow the player to switch between cameras.

## Emitted when the player picks a room to play audio in. [param room] is the camera node name,
## which matches the AnimatronicPosition name of that room.
signal audio_lure_requested(room: StringName)

## Emitted when the player starts ([param held] true) or stops holding the "wind up" button.
signal wind_up_held_changed(held: bool)

const WIND_READY_TEXT := "WIND UP"
const WIND_HELD_TEXT := "WINDING..."

const DEFAULT_CAM_INDEX = 0
const LURE_MARKER_COLOR := Color(0.95, 0.7, 0.25)

## Parent of the room lights. A light belongs to the camera whose node name its own name starts with
## (e.g. "ToyFactoryRimLight" -> "ToyFactory") and is only shown while that camera is being watched.
## Lights that match no camera are left untouched.
@export var lights_root: Node3D
## Cameras whose lights stay on even when the monitor is down because they are visible from the office.
@export var always_lit_cams: PackedStringArray = ["LeftHall", "RightHall"]

var selected_cam : Camera3D
var all_cams = {}
var cam_lights = {}	# Camera3D name -> Array[Light3D]

var _lure_cooldown := 0.0
var _lure_selecting := false
var _lure_markers: Array[Control] = []
var _lure_tween: Tween

@onready var cam_ui = $%CameraUI
@onready var cam_buttons_parent = $%CamButtonsParent
@onready var cam_click_sound = $CamClickSound
@onready var ui_animation_player = $CameraUI/AnimationPlayer
@onready var audio_lure_button: AudioLureButton = %AudioLureButton
@onready var audio_lure_hint: Label = %AudioLureHint
@onready var audio_lure_sound: AudioStreamPlayer = $AudioLureSound
@onready var wind_up_button: Button = %WindUpButton
@onready var wind_cooldown_ring: CooldownRing = %WindCooldownRing


func _ready():
	cam_ui.visible = false
	audio_lure_button.hide()
	audio_lure_hint.hide()
	audio_lure_button.pressed.connect(_on_audio_lure_button_pressed)
	wind_up_button.hide()
	wind_cooldown_ring.hide()
	wind_up_button.button_down.connect(_set_wind_up_held.bind(true))
	wind_up_button.button_up.connect(_set_wind_up_held.bind(false))

	# Add all cameras to the camera dictionary
	# Each key is the name of the camera in lowercase and the value is a reference to the Camera3D node.
	for c in get_children():
		if c is Camera3D:
			all_cams[c.name.to_lower()] = c
			c.current = false
	
	# Connect the cam_button_pressed signal from each camera button
	# to the set_current_cam function
	for c in cam_buttons_parent.get_children():
		if c is BaseButton:
			c.connect("cam_button_pressed", set_current_cam)
			_lure_markers.append(_make_lure_marker(c))
	
	# Set default cam
	if not all_cams.values().is_empty():
		selected_cam = all_cams.values()[DEFAULT_CAM_INDEX]
	else:
		printerr("no cameras are under camera manager")

	_collect_cam_lights()
	_update_lights()


func _collect_cam_lights():
	if lights_root == null:
		return
	for light in lights_root.get_children():
		if not light is Light3D:
			continue
		for cam_name in all_cams.values().map(func(c): return String(c.name)):
			if String(light.name).begins_with(cam_name):
				if not cam_lights.has(cam_name):
					cam_lights[cam_name] = []
				cam_lights[cam_name].append(light)
				break


## Only the lights of the watched camera (plus the always lit ones) are rendered, so the number
## of lights hitting the big building mesh stays under the Compatibility renderer's per-object cap.
func _update_lights():
	for cam_name in cam_lights:
		var lit : bool = cam_name in always_lit_cams \
			or (cam_ui.visible and selected_cam != null and selected_cam.name == cam_name)
		for light in cam_lights[cam_name]:
			light.visible = lit


## Shows the "play audio" button; it recharges for [param cooldown] seconds after every use.
func setup_audio_lure(cooldown : float):
	_lure_cooldown = cooldown
	audio_lure_button.show()


## Shows the "wind up" button and its cooldown ring.
func setup_wind_up():
	wind_up_button.show()
	wind_cooldown_ring.show()


## [param ratio] is the remaining share of the wind-up timer (1 = full); [param urgent] turns the ring red.
func set_wind_up_progress(ratio : float, urgent : bool):
	wind_cooldown_ring.ratio = ratio
	wind_cooldown_ring.urgent = urgent


func set_current_cam(cam : String):
	if _lure_selecting:
		_play_audio_lure(cam)
		return
	# set the previous camera as not current and hide it, switch to the new one and make that one current
	selected_cam.current = false
	selected_cam = all_cams[cam.to_lower()]
	selected_cam.current = true
	_update_lights()
	cam_click_sound.play()
	lose_communication(1.0)


func lose_communication(time_scale : float):
	ui_animation_player.stop()
	ui_animation_player.speed_scale = time_scale
	ui_animation_player.play("lost_communication")


## True while the monitor is up and the selected camera is the one named after [param position_name]
## (camera node names match AnimatronicPosition names, case-insensitive).


func is_watching(position_name : StringName) -> bool:
	return cam_ui.visible and selected_cam != null and selected_cam.name.to_lower() == String(position_name).to_lower()


func enable_camera_display():
	if selected_cam:
		selected_cam.current = true
	cam_ui.visible = true
	_update_lights()


func disable_camera_display():
	if selected_cam:
		selected_cam.current = false
	cam_ui.visible = false
	_set_lure_selecting(false)
	_set_wind_up_held(false)
	_update_lights()


func _set_wind_up_held(held : bool):
	wind_up_button.text = WIND_HELD_TEXT if held else WIND_READY_TEXT
	if held:
		cam_click_sound.play()
	wind_up_held_changed.emit(held)


func _on_audio_lure_button_pressed():
	_set_lure_selecting(not _lure_selecting)


## While selecting, every cam button shows a pulsing marker and pressing one plays the audio there
## instead of switching the camera.
func _set_lure_selecting(active : bool):
	if _lure_selecting == active:
		return
	_lure_selecting = active
	audio_lure_button.set_selecting(active)
	audio_lure_hint.visible = active

	if _lure_tween:
		_lure_tween.kill()
		_lure_tween = null
	for marker in _lure_markers:
		marker.visible = active
		marker.modulate.a = 1.0
	if active:
		_lure_tween = create_tween().set_loops().set_parallel(true)
		for marker in _lure_markers:
			_lure_tween.tween_property(marker, "modulate:a", 0.3, 0.5)
			_lure_tween.tween_property(marker, "modulate:a", 1.0, 0.5).set_delay(0.5)


func _play_audio_lure(room : String):
	_set_lure_selecting(false)
	audio_lure_sound.play()
	audio_lure_button.start_cooldown(_lure_cooldown)
	audio_lure_requested.emit(StringName(room))


func _make_lure_marker(cam_button : Control) -> Control:
	var marker := Panel.new()
	marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(LURE_MARKER_COLOR, 0.18)
	box.set_border_width_all(3)
	box.border_color = LURE_MARKER_COLOR
	box.corner_radius_top_left = 9
	box.corner_radius_bottom_right = 9
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.shadow_color = Color(LURE_MARKER_COLOR, 0.5)
	box.shadow_size = 8
	marker.add_theme_stylebox_override("panel", box)
	marker.hide()
	cam_button.add_child(marker)
	return marker
