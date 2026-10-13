extends Button
class_name AudioLureButton
## The monitor's "play audio" button. It owns its cooldown and shows it as a charging bar plus a countdown.
## All styling lives in camera_manager.tscn.

const READY_TEXT := "PLAY AUDIO"
const SELECTING_TEXT := "CANCEL"

var _cooldown_total := 0.0
var _cooldown_left := 0.0

@onready var _bar: ProgressBar = $CooldownBar


func _ready() -> void:
	text = READY_TEXT
	_bar.hide()
	set_process(false)


func is_on_cooldown() -> bool:
	return _cooldown_left > 0.0


func start_cooldown(seconds: float) -> void:
	_cooldown_total = seconds
	_cooldown_left = seconds
	disabled = true
	_bar.show()
	_update_display()
	set_process(true)


func set_selecting(active: bool) -> void:
	if not is_on_cooldown():
		text = SELECTING_TEXT if active else READY_TEXT


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_display()
	if _cooldown_left <= 0.0:
		set_process(false)


func _update_display() -> void:
	if _cooldown_left > 0.0:
		text = "COOLDOWN %ds" % ceili(_cooldown_left)
		_bar.value = 1.0 - _cooldown_left / _cooldown_total
	else:
		text = READY_TEXT
		disabled = false
		_bar.hide()
