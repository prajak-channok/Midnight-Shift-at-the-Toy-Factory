extends Node3D

@export var clock: Control
@export var blue_animatronic: Node3D
@export var yellow_animatronic: Node3D

@onready var left_door: Node = $Doors/LeftDoor
@onready var right_door: Node = $Doors/RightDoor
@onready var left_light: OmniLight3D = $VentLights/LeftLight
@onready var right_light: OmniLight3D = $VentLights/RightLight
@onready var player: Node = $Player
@onready var gui: Control = $PlayerControlsGUI

var power: float = 100.0
var game_over: bool = false
var night_complete: bool = false


func _ready() -> void:
	if clock == null:
		push_error("Night: Clock is not assigned.")
		return

	if clock.has_signal("six_am_reached"):
		clock.six_am_reached.connect(night_done)
	if clock.has_signal("hour_passed"):
		clock.hour_passed.connect(_on_hour_passed)

	_set_animatronic_ai(blue_animatronic, 4)
	_set_animatronic_ai(yellow_animatronic, 3)

	if Global.current_night >= 2:
		_set_animatronic_ai(blue_animatronic, 7)
		_set_animatronic_ai(yellow_animatronic, 6)

	_start_animatronic_ai(blue_animatronic)
	_start_animatronic_ai(yellow_animatronic)


func _process(delta: float) -> void:
	if game_over or night_complete:
		return

	var drain: float = 0.10
	if _door_is_closed(left_door):
		drain += 0.12
	if _door_is_closed(right_door):
		drain += 0.12
	if _player_monitor_is_on():
		drain += 0.04

	power = maxf(0.0, power - drain * delta)
	_set_gui_text("Status", "POWER %d%%" % int(power))

	if clock != null and clock.has_node("Label"):
		_set_gui_text("Time", str(clock.get_node("Label").text))

	if power <= 0.0:
		_force_door_open(left_door)
		_force_door_open(right_door)
		_set_gui_text("Status", "POWER 0% — DOORS OFF")


func _unhandled_input(event: InputEvent) -> void:
	if game_over or night_complete:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A:
				toggle_left_door()
			KEY_D:
				toggle_right_door()
			KEY_Z:
				toggle_left_light()
			KEY_C:
				toggle_right_light()


func toggle_left_door() -> void:
	if power <= 0.0:
		return
	_toggle_door(left_door)


func toggle_right_door() -> void:
	if power <= 0.0:
		return
	_toggle_door(right_door)


func toggle_left_light() -> void:
	if power <= 0.0:
		return
	left_light.visible = not left_light.visible


func toggle_right_light() -> void:
	if power <= 0.0:
		return
	right_light.visible = not right_light.visible


func toggle_camera() -> void:
	if power <= 0.0:
		return
	if player != null and player.has_method("toggle_monitor"):
		player.call("toggle_monitor")


func trigger_game_over(animatronic: Node) -> void:
	if game_over or night_complete:
		return
	game_over = true
	_force_door_open(left_door)
	_force_door_open(right_door)

	if player != null and player.has_method("force_monitor_down"):
		await player.call("force_monitor_down")
	await get_tree().create_timer(0.25).timeout

	var jumpscare: Node = null
	if animatronic == blue_animatronic:
		jumpscare = get_node_or_null("AnimatronicJumpscares/BlueAnimatronicJumpscare")
	else:
		jumpscare = get_node_or_null("AnimatronicJumpscares/YellowAnimatronicJumpscare")

	if jumpscare != null and jumpscare.has_method("play_jumpscare"):
		jumpscare.call("play_jumpscare")


func _on_hour_passed() -> void:
	if clock == null:
		return

	var current_hour: int = int(clock.get("current_hour"))
	if current_hour == 1:
		_set_animatronic_ai(blue_animatronic, _get_animatronic_ai(blue_animatronic) + 2)
	elif current_hour == 2:
		_set_animatronic_ai(yellow_animatronic, _get_animatronic_ai(yellow_animatronic) + 2)
	elif current_hour == 4:
		_set_animatronic_ai(blue_animatronic, _get_animatronic_ai(blue_animatronic) + 2)
		_set_animatronic_ai(yellow_animatronic, _get_animatronic_ai(yellow_animatronic) + 2)


func night_done() -> void:
	if game_over:
		return
	night_complete = true
	get_tree().change_scene_to_file("res://night/six_am/six_am.tscn")


func _door_is_closed(door: Node) -> bool:
	return door != null and bool(door.get("is_closed"))


func _toggle_door(door: Node) -> void:
	if door != null and door.has_method("toggle"):
		door.call("toggle")


func _force_door_open(door: Node) -> void:
	if door != null and door.has_method("force_open"):
		door.call("force_open")


func _player_monitor_is_on() -> bool:
	if player == null or not player.has_method("is_monitor_on"):
		return false
	return bool(player.call("is_monitor_on"))


func _set_animatronic_ai(animatronic: Node, value: int) -> void:
	if animatronic == null:
		return
	animatronic.set("ai_level", clampi(value, 0, 20))


func _get_animatronic_ai(animatronic: Node) -> int:
	if animatronic == null:
		return 0
	return int(animatronic.get("ai_level"))


func _start_animatronic_ai(animatronic: Node) -> void:
	if animatronic != null and animatronic.has_method("start_ai"):
		animatronic.call("start_ai")


func _set_gui_text(node_name: String, value: String) -> void:
	if gui == null:
		return
	var node: Node = gui.get_node_or_null(node_name)
	if node is Label:
		node.text = value
