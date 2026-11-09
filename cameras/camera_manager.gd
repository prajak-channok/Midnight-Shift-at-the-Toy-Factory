extends Node
class_name CameraManager

## ส่งสัญญาณเมื่อผู้เล่นเลือกห้องเพื่อเปิดเสียงล่อ (Emitted when player selects room to play audio lure)
signal audio_lure_requested(room: StringName)

## ส่งสัญญาณเมื่อผู้เล่นเริ่มหรือหยุดกดปุ่มไขลานค้างไว้ (Emitted when player starts or stops holding wind up button)
signal wind_up_held_changed(held: bool)

const LURE_SOUND_SECONDS := 5.0
const LURE_SOUND_FADE := 0.5
const WIND_READY_TEXT := "WIND UP"
const WIND_HELD_TEXT := "WINDING..."

const WIND_UP_CAM := &"StaffRoom" ## กล้องห้องพักพนักงานสำหรับแสดงปุ่มไขลานและวงแหวนคูลดาวน์ (Staff room camera for showing wind up button and cooldown ring)

const DEFAULT_CAM_INDEX = 0
const LURE_MARKER_COLOR := Color(0.95, 0.7, 0.25)

@export var lights_root: Node3D ## โหนดรูทของไฟแต่ละห้องในอาคาร (Root node of room lights)
@export var always_lit_cams: PackedStringArray = ["LeftHall", "RightHall"] ## กล้องที่เปิดไฟทิ้งไว้ตลอดเพราะมองเห็นได้จากห้องทำงาน (Cameras kept lit because visible from office)

@export var rooms_root: Node3D ## โหนดรูทของฉากห้องต่างๆ ในโรงงาน (Root node of factory room scenes)
@export var office_rooms: PackedStringArray = ["SecurityRoom", "LeftHall", "RightHall"] ## ห้องที่มองเห็นได้จากห้องทำงานจึงต้องเรนเดอร์ไว้ตลอด (Rooms visible from office that must stay rendered)

@export var extra_cam_rooms: Dictionary = {"FactoryTransferCorridor": ["ToyFactory"]} ## ห้องเสริมที่กล้องตัวนั้นๆ มองเห็นพ่วงด้วย (Extra rooms visible from specific cameras)

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


func _ready() -> void:
	cam_ui.visible = false
	_lure_sound_volume_db = audio_lure_sound.volume_db
	audio_lure_button.hide()
	audio_lure_hint.hide()
	audio_lure_button.pressed.connect(_on_audio_lure_button_pressed)
	wind_up_button.hide()
	wind_cooldown_ring.hide()
	wind_up_button.button_down.connect(_set_wind_up_held.bind(true))
	wind_up_button.button_up.connect(_set_wind_up_held.bind(false))

	# เก็บกล้องทั้งหมดลงดิกชันนารีโดยใช้ชื่อตัวพิมพ์เล็กเป็นคีย์ (Store all cameras in dictionary using lowercase names)
	for c in get_children():
		if c is Camera3D:
			all_cams[c.name.to_lower()] = c
			c.current = false
	
	# เชื่อมสัญญาณกดปุ่มกล้องเข้ากับฟังก์ชันสลับกล้อง (Connect camera button signals to switch camera function)
	for c in cam_buttons_parent.get_children():
		if c is BaseButton:
			if c.has_signal("cam_button_pressed"):
				c.cam_button_pressed.connect(set_current_cam)
			_all_lure_markers[String(c.camera_node_name).to_lower()] = _make_lure_marker(c)
	
	if not all_cams.values().is_empty():
		selected_cam = all_cams.values()[DEFAULT_CAM_INDEX]
	else:
		printerr("no cameras are under camera manager")

	_update_cam_buttons()
	_collect_cam_lights()
	_update_lights()
	_find_animatronics()
	_update_rooms()
	_warm_up()


## เรนเดอร์กล้องทุกตัวตัวละหนึ่งเฟรมเพื่อคอมไพล์เชดเดอร์ระหว่างหน้าจอโหลด (Pre-render each camera for one frame to compile shaders during loading screen)
func _warm_up() -> void:
	var tree := get_tree()
	if tree.get_nodes_in_group(LoadingOverlay.GROUP).is_empty() or all_cams.is_empty():
		return
	tree.paused = true
	await tree.process_frame # รอให้ห้องทำงานเรนเดอร์เสร็จก่อน (Wait for office to be drawn first)

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


## แสดงเฉพาะห้องที่กำลังดูกล้องหรือมองเห็นจากห้องทำงานเพื่อประหยัดการเรนเดอร์ (Show only watched or office-visible rooms to optimize rendering)
func _update_rooms() -> void:
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


func _process(_delta: float) -> void:
	var moved := false
	for animatronic in _animatronics:
		if _animatronic_last.get(animatronic) != animatronic.global_position:
			_animatronic_last[animatronic] = animatronic.global_position
			moved = true
	if moved:
		_update_animatronics()


func _find_animatronics() -> void:
	var night := get_parent()
	for node in night.find_children("*", "AnimatronicBase", true, false):
		_animatronics.append(node)
	for node in night.find_children("*", "AnimatronicPosition", true, false):
		_spots.append(node)


## ซ่อนโมเดลหุ่นเมื่อห้องที่หุ่นยืนอยู่ถูกคัดออกจากการเรนเดอร์ (Hide animatronics when their containing room is culled from rendering)
func _update_animatronics() -> void:
	for animatronic in _animatronics:
		var room := _room_of(animatronic)
		var show_it := room == &"" or _shown_rooms.has(room)
		if show_it and animatronic.has_meta(ROOM_CULLED_META):
			animatronic.remove_meta(ROOM_CULLED_META)
			animatronic.visible = true
		elif not show_it and animatronic.visible:
			animatronic.set_meta(ROOM_CULLED_META, true)
			animatronic.visible = false


## หาชื่อห้องที่หุ่นยืนอยู่โดยเทียบจากตำแหน่งมาร์กเกอร์หรือจุดศูนย์กลางห้อง (Find room where animatronic stands based on marker or room center)
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


func _collect_cam_lights() -> void:
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


## เปิดเฉพาะไฟของห้องที่กำลังดูอยู่เพื่อไม่ให้เกินขีดจำกัดของ Compatibility renderer (Enable only lights of currently watched room to stay within renderer limits)
func _update_lights() -> void:
	for cam_name in cam_lights:
		var lit : bool = cam_name in always_lit_cams \
			or (cam_ui.visible and selected_cam != null and selected_cam.name == cam_name)
		for light in cam_lights[cam_name]:
			light.visible = lit


## เปิดใช้งานปุ่มล่อด้วยเสียงและกำหนดห้องที่สามารถเล่นเสียงได้ (Setup audio lure button and designate selectable rooms)
func setup_audio_lure(cooldown: float, rooms: Array[StringName]) -> void:
	_lure_cooldown = cooldown
	_lure_rooms.clear()
	_lure_markers.clear()
	for room in rooms:
		var key := String(room).to_lower()
		_lure_rooms.append(key)
		if _all_lure_markers.has(key):
			_lure_markers.append(_all_lure_markers[key])
	audio_lure_button.show()


## เปิดใช้งานปุ่มไขลานและวงแหวนคูลดาวน์ (Enable wind up button and cooldown ring)
func setup_wind_up() -> void:
	_wind_up_enabled = true
	_update_wind_up_visibility()


func _update_wind_up_visibility() -> void:
	var visible_now := _wind_up_enabled and is_watching(WIND_UP_CAM)
	if not visible_now and wind_up_button.visible:
		_set_wind_up_held(false)
	wind_up_button.visible = visible_now
	wind_cooldown_ring.visible = visible_now


## อัปเดตสัดส่วนเวลาไขลานที่เหลือและแจ้งเตือนสีแดงเมื่อเข้าขั้นวิกฤต (Update remaining wind up ratio and turn red on urgent warning)
func set_wind_up_progress(ratio: float, urgent: bool) -> void:
	wind_cooldown_ring.ratio = ratio
	wind_cooldown_ring.urgent = urgent


## Highlights the button of the watched camera so it stands out from the other cam buttons.
func _update_cam_buttons() -> void:
	if selected_cam == null:
		return
	for c in cam_buttons_parent.get_children():
		if c is BaseButton and "selected" in c:
			c.selected = String(c.camera_node_name).to_lower() == String(selected_cam.name).to_lower()


func set_current_cam(cam: String) -> void:
	if _lure_selecting:
		if cam.to_lower() in _lure_rooms:
			_play_audio_lure(cam)
		return
	# สลับการแสดงผลจากกล้องเดิมไปยังกล้องใหม่ที่เลือก (Switch active camera to the newly selected one)
	selected_cam.current = false
	selected_cam = all_cams[cam.to_lower()]
	selected_cam.current = true
	_update_cam_buttons()
	_update_lights()
	_update_rooms()
	_update_wind_up_visibility()
	cam_click_sound.play()
	lose_communication(1.0)


func lose_communication(time_scale: float) -> void:
	ui_animation_player.stop()
	ui_animation_player.speed_scale = time_scale
	ui_animation_player.play("lost_communication")


## เช็คว่าผู้เล่นกำลังเปิดมอนิเตอร์ดูกล้องที่ห้องนี้อยู่หรือไม่ (Check if player is viewing this room on the monitor)
func is_watching(position_name : StringName) -> bool:
	return cam_ui.visible and selected_cam != null and selected_cam.name.to_lower() == String(position_name).to_lower()


func enable_camera_display() -> void:
	if selected_cam:
		selected_cam.current = true
	cam_ui.visible = true
	_update_lights()
	_update_rooms()
	_update_wind_up_visibility()


func disable_camera_display() -> void:
	if selected_cam:
		selected_cam.current = false
	cam_ui.visible = false
	_set_lure_selecting(false)
	_set_wind_up_held(false)
	_update_lights()
	_update_rooms()
	_update_wind_up_visibility()


func _set_wind_up_held(held: bool) -> void:
	wind_up_button.text = WIND_HELD_TEXT if held else WIND_READY_TEXT
	if held:
		wind_up_sound.play()
	wind_up_held_changed.emit(held)


func _on_audio_lure_button_pressed() -> void:
	_set_lure_selecting(not _lure_selecting)


## สลับโหมดเลือกห้องเพื่อเปิดเสียงล่อโดยจะแสดงมาร์กเกอร์กระพริบ (Toggle audio lure targeting mode with pulsing markers)
func _set_lure_selecting(active: bool) -> void:
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


func _play_audio_lure(room: String) -> void:
	_set_lure_selecting(false)
	_play_lure_sound()
	audio_lure_button.start_cooldown(_lure_cooldown)
	audio_lure_requested.emit(StringName(room))


## เล่นเสียงดนตรีล่อหุ่นและค่อยๆ หรี่เสียงลงตอนท้าย (Play lure audio stream and fade out at the end)
func _play_lure_sound() -> void:
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
