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

const LURE_SOUND_SECONDS := 5.0
const LURE_SOUND_FADE := 0.5
const WIND_READY_TEXT := "WIND UP"
const WIND_HELD_TEXT := "WINDING..."

const WIND_UP_CAM := &"StaffRoom" ## Cam 5: the only camera that shows the wind up button and its cooldown ring.

const DEFAULT_CAM_INDEX = 0
const LURE_MARKER_COLOR := Color(0.95, 0.7, 0.25)

## Parent of the room lights. A light belongs to the camera whose node name its own name starts with
## (e.g. "ToyFactoryRimLight" -> "ToyFactory") and is only shown while that camera is being watched.
## Lights that match no camera are left untouched.
@export var lights_root: Node3D
## Cameras whose lights stay on even when the monitor is down because they are visible from the office.
@export var always_lit_cams: PackedStringArray = ["LeftHall", "RightHall"]

## Parent of the room scenes (FactoryMap). Only the rooms visible from the current view are rendered.
@export var rooms_root: Node3D
## Rooms that can be seen from the office; the halls stay on because the doors and windows look into them.
@export var office_rooms: PackedStringArray = ["SecurityRoom", "LeftHall", "RightHall"]

## Rooms a camera can see besides its own, e.g. the corridor camera looks into the ToyFactory.
@export var extra_cam_rooms: Dictionary = {"FactoryTransferCorridor": ["ToyFactory"]}

const ANIMATRONIC_SPOT_DISTANCE := 0.5
const ANIMATRONIC_ROOM_DISTANCE := 2.5
const ROOM_CULLED_META := &"room_culled"

var selected_cam : Camera3D
var all_cams = {}
var cam_lights = {}	# Camera3D name -> Array[Light3D]

var _animatronics: Array[Node3D] = []
var _spots: Array[Node3D] = []
var _animatronic_last := {} # animatronic -> last global position
var _shown_rooms := {} # names of the rooms that are currently rendered

var _wind_up_enabled := false
var _lure_cooldown := 0.0
var _lure_selecting := false
var _all_lure_markers := {} # lowercase cam name -> marker
var _lure_markers: Array[Control] = [] # markers of the rooms the audio can be played in
var _lure_rooms: Array[String] = [] # lowercase names of those rooms
var _lure_tween: Tween
var _lure_sound_tween: Tween
var _lure_sound_volume_db := 0.0

@onready var cam_ui = $%CameraUI
@onready var cam_buttons_parent = $%CamButtonsParent
@onready var cam_click_sound = $CamClickSound
@onready var ui_animation_player = $CameraUI/AnimationPlayer
@onready var audio_lure_button: AudioLureButton = %AudioLureButton
@onready var audio_lure_hint: Label = %AudioLureHint
@onready var audio_lure_sound: AudioStreamPlayer = $AudioLureSound
@onready var wind_up_sound: AudioStreamPlayer = $WindUpSound
@onready var wind_up_button: Button = %WindUpButton
@onready var wind_cooldown_ring: CooldownRing = %WindCooldownRing


func _ready():
	cam_ui.visible = false
	_lure_sound_volume_db = audio_lure_sound.volume_db
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
			_all_lure_markers[String(c.camera_node_name).to_lower()] = _make_lure_marker(c)
	
	# Set default cam
	if not all_cams.values().is_empty():
		selected_cam = all_cams.values()[DEFAULT_CAM_INDEX]
	else:
		printerr("no cameras are under camera manager")

	_collect_cam_lights()
	_update_lights()
	_find_animatronics()
	_update_rooms()
	_warm_up()


## While the loading overlay is still up, the night is paused and every camera is shown for one frame,
## so the shaders of each room and light setup compile (one frame at a time) behind the loading screen
## instead of causing a hitch the first time the player opens that camera.
func _warm_up():
	var tree := get_tree()
	if tree.get_nodes_in_group(LoadingOverlay.GROUP).is_empty() or all_cams.is_empty():
		return
	tree.paused = true
	await tree.process_frame # the office gets drawn first

	var office_cam := selected_cam
	cam_ui.visible = true
	for cam: Camera3D in all_cams.values():
		selected_cam.current = false
		selected_cam = cam
		cam.current = true
		_update_lights()
		_update_rooms()
		await tree.process_frame
	selected_cam.current = false
	selected_cam = office_cam
	cam_ui.visible = false
	_update_lights()
	_update_rooms()

	await tree.process_frame
	tree.paused = false
	LoadingOverlay.dismiss(tree)


## Each camera only sees the room it is named after, and the office only sees [member office_rooms];
## everything else is hidden so its meshes are not sent to the GPU.
func _update_rooms():
	if rooms_root == null:
		return
	var watching: bool = cam_ui.visible and selected_cam != null
	var extra: Array = []
	if watching:
		extra = extra_cam_rooms.get(String(selected_cam.name), [])
	_shown_rooms.clear()
	for room in rooms_root.get_children():
		if room is Node3D:
			if watching:
				room.visible = room.name == selected_cam.name or String(room.name) in extra
			else:
				room.visible = office_rooms.has(String(room.name))
			if room.visible:
				_shown_rooms[room.name] = true
	_update_animatronics()


func _process(_delta: float):
	var moved := false
	for animatronic in _animatronics:
		if _animatronic_last.get(animatronic) != animatronic.global_position:
			_animatronic_last[animatronic] = animatronic.global_position
			moved = true
	if moved:
		_update_animatronics()


func _find_animatronics():
	var night := get_parent()
	for node in night.find_children("*", "AnimatronicBase", true, false):
		_animatronics.append(node)
	for node in night.find_children("*", "AnimatronicPosition", true, false):
		_spots.append(node)


## Animatronics are not part of the rooms, so without this they would be drawn through the walls
## even while the room they stand in is hidden. Animatronics whose room can't be told are always shown.
func _update_animatronics():
	for animatronic in _animatronics:
		var room := _room_of(animatronic)
		var show_it := room == &"" or _shown_rooms.has(room)
		if show_it and animatronic.has_meta(ROOM_CULLED_META):
			animatronic.remove_meta(ROOM_CULLED_META)
			animatronic.visible = true
		elif not show_it and animatronic.visible:
			animatronic.set_meta(ROOM_CULLED_META, true)
			animatronic.visible = false


## The room an animatronic stands in: the room named by the AnimatronicPosition it was placed on,
## or else the room whose center it is next to. Empty when it isn't clearly in any room.
func _room_of(animatronic: Node3D) -> StringName:
	var pos := animatronic.global_position
	var best := ANIMATRONIC_SPOT_DISTANCE
	var spot_name := &""
	for spot in _spots:
		var d := spot.global_position.distance_to(pos)
		if d < best:
			best = d
			spot_name = spot.name
	if spot_name != &"":
		return spot_name if rooms_root.has_node(NodePath(spot_name)) else &""

	best = ANIMATRONIC_ROOM_DISTANCE
	var room_name := &""
	for room in rooms_root.get_children():
		if room is Node3D:
			var d: float = room.global_position.distance_to(pos)
			if d < best:
				best = d
				room_name = room.name
	return room_name


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
## Audio can only be played in [param rooms]; the other cameras are neither highlighted nor selectable for it.
func setup_audio_lure(cooldown : float, rooms : Array[StringName]):
	_lure_cooldown = cooldown
	_lure_rooms.clear()
	_lure_markers.clear()
	for room in rooms:
		var key := String(room).to_lower()
		_lure_rooms.append(key)
		if _all_lure_markers.has(key):
			_lure_markers.append(_all_lure_markers[key])
	audio_lure_button.show()


## Enables the "wind up" button and its cooldown ring; they only show while the [constant WIND_UP_CAM] camera is watched.
func setup_wind_up():
	_wind_up_enabled = true
	_update_wind_up_visibility()


func _update_wind_up_visibility():
	var visible_now := _wind_up_enabled and is_watching(WIND_UP_CAM)
	if not visible_now and wind_up_button.visible:
		_set_wind_up_held(false)
	wind_up_button.visible = visible_now
	wind_cooldown_ring.visible = visible_now


## [param ratio] is the remaining share of the wind-up timer (1 = full); [param urgent] turns the ring red.
func set_wind_up_progress(ratio : float, urgent : bool):
	wind_cooldown_ring.ratio = ratio
	wind_cooldown_ring.urgent = urgent


func set_current_cam(cam : String):
	if _lure_selecting:
		if cam.to_lower() in _lure_rooms:
			_play_audio_lure(cam)
		return
	# set the previous camera as not current and hide it, switch to the new one and make that one current
	selected_cam.current = false
	selected_cam = all_cams[cam.to_lower()]
	selected_cam.current = true
	_update_lights()
	_update_rooms()
	_update_wind_up_visibility()
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
	_update_rooms()
	_update_wind_up_visibility()


func disable_camera_display():
	if selected_cam:
		selected_cam.current = false
	cam_ui.visible = false
	_set_lure_selecting(false)
	_set_wind_up_held(false)
	_update_lights()
	_update_rooms()
	_update_wind_up_visibility()


func _set_wind_up_held(held : bool):
	wind_up_button.text = WIND_HELD_TEXT if held else WIND_READY_TEXT
	if held:
		wind_up_sound.play()
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
	_play_lure_sound()
	audio_lure_button.start_cooldown(_lure_cooldown)
	audio_lure_requested.emit(StringName(room))


## Plays the lure sound for at most [constant LURE_SOUND_SECONDS], fading out over the last [constant LURE_SOUND_FADE].
func _play_lure_sound():
	if _lure_sound_tween:
		_lure_sound_tween.kill()
	audio_lure_sound.volume_db = _lure_sound_volume_db
	audio_lure_sound.play()
	_lure_sound_tween = create_tween()
	_lure_sound_tween.tween_interval(LURE_SOUND_SECONDS - LURE_SOUND_FADE)
	_lure_sound_tween.tween_property(audio_lure_sound, "volume_db", -60.0, LURE_SOUND_FADE)
	_lure_sound_tween.tween_callback(audio_lure_sound.stop)


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
