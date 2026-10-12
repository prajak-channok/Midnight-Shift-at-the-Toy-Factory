extends Control
class_name NightHud

signal monitor_requested
signal quit_confirmed

## A tap on touch screens also fires mouse_entered right before pressed; presses this soon after a hover are ignored.
const HOVER_PRESS_GRACE_MSEC := 300

@onready var status: Label = $Status
@onready var quit_button: Button = %QuitButton
@onready var quit_popup: Control = %QuitPopup
@onready var cancel_button: Button = %CancelButton
@onready var confirm_quit_button: Button = %ConfirmQuitButton

var _last_hover_msec: int = -HOVER_PRESS_GRACE_MSEC


func _ready() -> void:
	quit_button.pressed.connect(_open_quit_popup)
	cancel_button.pressed.connect(_close_quit_popup)
	confirm_quit_button.pressed.connect(_on_confirm_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if quit_popup.visible and event.is_action_pressed("ui_cancel"):
		_close_quit_popup()
		get_viewport().set_input_as_handled()


func hide_quit_button() -> void:
	quit_button.hide()


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


## The HUD keeps processing while paused so the popup stays clickable; the rest of the night freezes.
func _open_quit_popup() -> void:
	get_tree().paused = true
	quit_popup.show()


func _close_quit_popup() -> void:
	quit_popup.hide()
	get_tree().paused = false


func _on_confirm_quit_pressed() -> void:
	quit_confirmed.emit()
