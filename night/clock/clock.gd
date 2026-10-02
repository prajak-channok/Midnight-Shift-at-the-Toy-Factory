extends Control
class_name NightClock

signal hour_passed
signal six_am_reached

@export var seconds_between_hours := 60.0

@onready var label: Label = $Label
var current_hour := 0

func _ready():
	_start_counting.call_deferred()

func _start_counting():
	while current_hour < 6:
		label.text = _get_current_hour_text()
		await get_tree().create_timer(seconds_between_hours).timeout
		current_hour += 1
		hour_passed.emit()
	six_am_reached.emit()

func _get_current_hour_text() -> String:
	return "12 AM" if current_hour == 0 else str(current_hour) + " AM"
