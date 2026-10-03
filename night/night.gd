extends Node3D
class_name Night

@export var clock: NightClock
@export var blue_animatronic: FnafAnimatronic
@export var yellow_animatronic: FnafAnimatronic
@export var difficulties: Array[NightDifficulty] ## Index 0 = night 1.

@onready var left_door: Door = $Doors/LeftDoor
@onready var right_door: Door = $Doors/RightDoor
@onready var left_light: VentLight = $VentLights/LeftLight
@onready var right_light: VentLight = $VentLights/RightLight
@onready var player: Player = $Player
@onready var hud: NightHud = $PlayerControlsGUI
@onready var power_system: PowerSystem = $PowerSystem
@onready var blue_jumpscare: AnimatronicJumpscare = $AnimatronicJumpscares/BlueAnimatronicJumpscare
@onready var yellow_jumpscare: AnimatronicJumpscare = $AnimatronicJumpscares/YellowAnimatronicJumpscare

var difficulty: NightDifficulty
var game_over: bool = false
var night_complete: bool = false


func _ready() -> void:
	left_light.hide()
	right_light.hide()

	difficulty = _pick_difficulty()
	if clock == null or difficulty == null:
		push_error("Night: Clock or difficulties are not assigned.")
		return

	clock.six_am_reached.connect(night_done)
	clock.hour_passed.connect(_on_hour_passed)

	for node: Node in get_tree().get_nodes_in_group(LightButton.GROUP):
		(node as LightButton).pressed.connect(_on_light_button_pressed)

	hud.left_door_pressed.connect(toggle_left_door)
	hud.right_door_pressed.connect(toggle_right_door)
	hud.left_light_pressed.connect(toggle_left_light)
	hud.right_light_pressed.connect(toggle_right_light)
	hud.camera_pressed.connect(toggle_camera)

	power_system.power_changed.connect(hud.set_power)
	power_system.power_depleted.connect(_on_power_depleted)

	blue_animatronic.ai_level = difficulty.blue_ai
	yellow_animatronic.ai_level = difficulty.yellow_ai

	var doors: Array[Door] = [left_door, right_door]
	var lights: Array[VentLight] = [left_light, right_light]
	power_system.start(difficulty, doors, lights, player)

	blue_animatronic.start_ai()
	yellow_animatronic.start_ai()


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
		toggle_camera()


func toggle_left_door() -> void:
	if power_system.has_power():
		left_door.toggle()


func toggle_right_door() -> void:
	if power_system.has_power():
		right_door.toggle()


func toggle_left_light() -> void:
	if power_system.has_power():
		left_light.visible = not left_light.visible


func toggle_right_light() -> void:
	if power_system.has_power():
		right_light.visible = not right_light.visible


func toggle_camera() -> void:
	if power_system.has_power():
		player.toggle_monitor()


func trigger_game_over(animatronic: FnafAnimatronic) -> void:
	if game_over or night_complete:
		return
	game_over = true
	_stop_animatronics()
	power_system.stop()
	left_door.force_open()
	right_door.force_open()

	await player.force_monitor_down()
	await get_tree().create_timer(0.25).timeout

	var jumpscare: AnimatronicJumpscare = blue_jumpscare if animatronic == blue_animatronic else yellow_jumpscare
	jumpscare.play_jumpscare()


func night_done() -> void:
	if game_over:
		return
	night_complete = true
	_stop_animatronics()
	power_system.stop()
	get_tree().change_scene_to_file("res://night/six_am/six_am.tscn")


func _stop_animatronics() -> void:
	blue_animatronic.stop_ai()
	yellow_animatronic.stop_ai()


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


func _on_hour_passed() -> void:
	var hour: int = clock.current_hour
	_add_ai(blue_animatronic, difficulty.blue_bonus_for_hour(hour))
	_add_ai(yellow_animatronic, difficulty.yellow_bonus_for_hour(hour))


func _add_ai(animatronic: FnafAnimatronic, amount: int) -> void:
	animatronic.ai_level = clampi(animatronic.ai_level + amount, 0, AnimatronicBase.MAX_AI_LEVEL)


func _on_power_depleted() -> void:
	left_door.force_open()
	right_door.force_open()
	hud.show_power_out()
	player.force_monitor_down()
