extends Node3D
class_name Night

@export var clock: NightClock
@export var animatronics: Array[AnimatronicBase] = []
@export var difficulties: Array[NightDifficulty] ## Index 0 = night 1.

@onready var left_door: Door = $Doors/LeftDoor
@onready var right_door: Door = $Doors/RightDoor
@onready var left_light: VentLight = $VentLights/LeftLight
@onready var left_light2: VentLight = $VentLights/LeftLight2
@onready var right_light: VentLight = $VentLights/RightLight
@onready var right_light2: VentLight = $VentLights/RightLight2
@onready var player: Player = $Player
@onready var hud: NightHud = $PlayerControlsGUI
@onready var power_system: PowerSystem = $PowerSystem

var difficulty: NightDifficulty
var game_over: bool = false
var night_complete: bool = false


func _ready() -> void:
	left_light.hide()
	left_light2.hide()
	right_light.hide()
	right_light2.hide()

	difficulty = _pick_difficulty()
	if clock == null or difficulty == null:
		push_error("Night: Clock or difficulties are not assigned.")
		return

	clock.six_am_reached.connect(night_done)
	clock.hour_passed.connect(_on_hour_passed)

	for node: Node in get_tree().get_nodes_in_group(LightButton.GROUP):
		(node as LightButton).pressed.connect(_on_light_button_pressed)

	for node: Node in get_tree().get_nodes_in_group(DoorButton.GROUP):
		(node as DoorButton).pressed.connect(_on_door_button_pressed)

	hud.monitor_requested.connect(toggle_monitor)

	power_system.power_changed.connect(hud.set_power)
	power_system.power_depleted.connect(_on_power_depleted)

	for animatronic in animatronics:
		if difficulty.get_profile(animatronic.id) == null:
			push_warning("Night: no AI profile for animatronic '%s' (id '%s'), AI level stays 0." % [animatronic.name, animatronic.id])
		animatronic.ai_level = difficulty.base_ai_for(animatronic.id)
		animatronic.reached_office.connect(trigger_game_over.bind(animatronic))

	var doors: Array[Door] = [left_door, right_door]
	var lights: Array[VentLight] = [left_light, right_light]
	power_system.start(difficulty, doors, lights, player)

	for animatronic in animatronics:
		animatronic.start_ai()


func _unhandled_input(event: InputEvent) -> void:
	if game_over or night_complete:
		return
	if event.is_action_pressed("left_door"):
		toggle_left_door()
	elif event.is_action_pressed("right_door"):
		toggle_right_door()
	elif event.is_action_pressed("left_light"):
		toggle_left_light()
	elif event.is_action_pressed("right_light"):
		toggle_right_light()
	elif event.is_action_pressed("toggle_monitor"):
		toggle_monitor()


func can_use_office_controls() -> bool:
	return power_system.has_power() and not player.is_monitor_on()


func toggle_left_door() -> void:
	if can_use_office_controls():
		left_door.toggle()


func toggle_right_door() -> void:
	if can_use_office_controls():
		right_door.toggle()


func toggle_left_light() -> void:
	if can_use_office_controls():
		left_light.visible = not left_light.visible
		left_light2.visible = not left_light2.visible


func toggle_right_light() -> void:
	if can_use_office_controls():
		right_light.visible = not right_light.visible
		right_light2.visible = not right_light2.visible


func toggle_monitor() -> void:
	if game_over or night_complete:
		return
	if power_system.has_power():
		player.toggle_monitor()


func trigger_game_over(animatronic: AnimatronicBase) -> void:
	if game_over or night_complete:
		return
	game_over = true
	_stop_animatronics()
	power_system.stop()
	left_door.force_open()
	right_door.force_open()

	await player.force_monitor_down()
	await get_tree().create_timer(0.25).timeout

	if animatronic.jumpscare == null:
		push_error("Night: animatronic '%s' has no jumpscare assigned." % animatronic.name)
		return
	animatronic.jumpscare.play_jumpscare()


func night_done() -> void:
	if game_over:
		return
	night_complete = true
	_stop_animatronics()
	power_system.stop()
	get_tree().change_scene_to_file("res://night/six_am/six_am.tscn")


func _stop_animatronics() -> void:
	for animatronic in animatronics:
		animatronic.stop_ai()


func _pick_difficulty() -> NightDifficulty:
	if difficulties.is_empty():
		return null
	return difficulties[clampi(Global.current_night, 1, difficulties.size()) - 1]


func _on_light_button_pressed(side: String) -> void:
	if game_over or night_complete:
		return
	if side == "Left":
		toggle_left_light()
	else:
		toggle_right_light()


func _on_door_button_pressed(side: String) -> void:
	if game_over or night_complete:
		return
	if side == "Left":
		toggle_left_door()
	else:
		toggle_right_door()


func _on_hour_passed() -> void:
	var hour: int = clock.current_hour
	for animatronic in animatronics:
		var amount := difficulty.bonus_for_hour(animatronic.id, hour)
		animatronic.ai_level = clampi(animatronic.ai_level + amount, 0, AnimatronicBase.MAX_AI_LEVEL)


func _on_power_depleted() -> void:
	left_door.force_open()
	right_door.force_open()
	hud.show_power_out()
	player.force_monitor_down()
