extends AnimatronicBase
class_name WoundUpTinSoldier
## Wound-Up Tin Soldier: sits in the staff room and never moves. On nights listed in [constant ACTIVE_NIGHTS]
## a wind-up timer starts at [constant START_COOLDOWN] seconds and ticks down one second per second. While the
## monitor's "wind up" button is held the timer instead climbs [constant WIND_RATE] seconds per second (capped at the starting value). He opens his eyes when
## [constant AWAKE_AT] seconds or less are left; at zero the monitor is forced down, he jumpscares and the night is lost.

const ACTIVE_NIGHTS: Array[int] = [4, 5]
const START_COOLDOWN := 15.0
const WIND_RATE := 1.25 ## Timer seconds gained per real second while winding.
const AWAKE_AT := 5.0
const WARNING_AT := 3.0 ## The monitor's cooldown ring turns red at or below this.

const ANIM_ASLEEP := &"idle"
const ANIM_AWAKE := &"awake"

@export var cam_manager: CameraManager ## Hosts the wind-up button and its cooldown ring.
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
	if not is_active_tonight():
		hide()


static func is_active_tonight() -> bool:
	return Global.current_night in ACTIVE_NIGHTS


func start_ai() -> void:
	if not is_active_tonight():
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
		cooldown_left = maxf(cooldown_left - delta, 0.0)
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
