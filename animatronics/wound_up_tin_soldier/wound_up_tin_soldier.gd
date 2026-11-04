extends AnimatronicBase
class_name WoundUpTinSoldier

const START_COOLDOWN := 20.0
const WIND_RATE := 2.5 ## สเกลการเพิ่มของคูลดาวน์ (Cooldown increase rate)
const COOLDOWN_RATE := 0.5 ## สเกลการลดลงของคูลดาวน์ (Cooldown decrease rate)
const AWAKE_AT := 5.0
const WARNING_AT := 3.0 ## เวลาในการเปลี่ยนสีวงแหวนเพื่อเตือน (Time at which the ring changes color as a warning)

const ANIM_ASLEEP := &"idle"
const ANIM_AWAKE := &"awake"

@export var cam_manager: CameraManager
@export var animation_player_path: NodePath

var cooldown_left := START_COOLDOWN

var _running := false
var _winding := false
var _awake := false
var _animation_player: AnimationPlayer


func _init() -> void:
	forces_monitor_down = true


func _ready() -> void:
	_animation_player = get_node_or_null(animation_player_path)
	set_process(false)


## เปิดปุ่มไขลานและวงแหวนตั้งแต่เริ่มด่าน ก่อน AI เริ่มทำงาน (Show the wind up button and ring from the start of the night, before the AI runs)
func place_at_start() -> void:
	if ai_level <= 0: # หุ่นตัวนี้ใช้ AI level เป็นแค่สวิตช์เปิด/ปิดตามคืน (AI level is only an on/off switch per night)
		return
	if cam_manager == null:
		push_error("%s: no CameraManager assigned." % name)
		return

	cooldown_left = START_COOLDOWN
	_set_awake(false)
	cam_manager.setup_wind_up()
	if not cam_manager.wind_up_held_changed.is_connected(_on_wind_up_held_changed):
		cam_manager.wind_up_held_changed.connect(_on_wind_up_held_changed)
	_update_ui()


func start_ai() -> void:
	if ai_level <= 0 or cam_manager == null:
		return

	_running = true
	set_process(true)


func stop_ai() -> void:
	_running = false
	_winding = false
	set_process(false)


func _on_wind_up_held_changed(held: bool) -> void:
	_winding = held and _running


func _process(delta: float) -> void:
	if _winding:
		cooldown_left = minf(cooldown_left + WIND_RATE * delta, START_COOLDOWN)
	else:
		cooldown_left = maxf(cooldown_left - (delta * COOLDOWN_RATE), 0.0)
	_refresh()
	if cooldown_left <= 0.0:
		stop_ai()
		reached_office.emit()


func _refresh() -> void:
	_set_awake(cooldown_left <= AWAKE_AT)
	_update_ui()


func _update_ui() -> void:
	cam_manager.set_wind_up_progress(cooldown_left / START_COOLDOWN, cooldown_left <= WARNING_AT)


func _set_awake(awake: bool) -> void:
	if _awake == awake and _animation_player != null and _animation_player.is_playing():
		return
	_awake = awake
	if _animation_player:
		_animation_player.play(ANIM_AWAKE if awake else ANIM_ASLEEP)
