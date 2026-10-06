extends Control
class_name NightHud

signal monitor_requested

## A tap on touch screens also fires mouse_entered right before pressed; presses this soon after a hover are ignored.
const HOVER_PRESS_GRACE_MSEC := 300

@onready var status: Label = $Status

var _last_hover_msec: int = -HOVER_PRESS_GRACE_MSEC


func set_power(percent: int) -> void:
	status.text = "POWER %d%%" % percent


func show_power_out() -> void:
	status.text = "POWER 0% — DOORS OFF"


func _on_monitor_mouse_entered() -> void:
	_last_hover_msec = Time.get_ticks_msec()
	monitor_requested.emit()


func _on_monitor_pressed() -> void:
	if Time.get_ticks_msec() - _last_hover_msec < HOVER_PRESS_GRACE_MSEC:
		return
	monitor_requested.emit()
