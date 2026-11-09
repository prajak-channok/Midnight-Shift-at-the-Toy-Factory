extends Control
class_name NightClock

signal hour_passed
signal six_am_reached

@export var seconds_between_hours := 60.0 ## จำนวนวินาทีต่อ 1 ชั่วโมงในเกม (Seconds per in-game hour)

@onready var label: Label = $Label
var current_hour := 0
var _running := true


func _ready() -> void:
	_start_counting.call_deferred()


func stop() -> void:
	_running = false


func _start_counting() -> void:
	while current_hour < 6 and _running:
		label.text = _get_current_hour_text()
		await get_tree().create_timer(seconds_between_hours).timeout
		if not is_inside_tree() or not _running:
			return
		current_hour += 1
		hour_passed.emit()
	if _running:
		six_am_reached.emit()


func _get_current_hour_text() -> String:
	return "12 AM" if current_hour == 0 else str(current_hour) + " AM"
