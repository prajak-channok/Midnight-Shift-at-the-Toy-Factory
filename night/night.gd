extends Node3D
class_name Night

const AI_START_DELAY := 20.0 ## Seconds after the night begins before the toys start moving.
const SCENE_SIX_AM := "res://night/six_am/six_am.tscn"
const SCENE_MAIN_MENU := "res://main_menu/main_menu.tscn"
const MONITOR_WAIT_TIMEOUT := 2.0

@export_group("Dependencies")
@export var clock: NightClock
@export var player: Player
@export var hud: NightHud
@export var power_system: PowerSystem
@export var left_door: Door
@export var right_door: Door
@export var left_light: DoorLight
@export var right_light: DoorLight
@export var animatronics: Array[AnimatronicBase] = []

@export_group("Settings")
@export var difficulties: Array[NightDifficulty] = [] ## Index 0 = night 1.

var difficulty: NightDifficulty
var game_over: bool = false
var night_complete: bool = false


func _ready() -> void:
	difficulty = _pick_difficulty()
	if clock == null or difficulty == null:
		push_error("Night: Clock or difficulties are not assigned.")
		set_process_unhandled_input(false)
		return

	if left_light != null:
		left_light.hide()
	if right_light != null:
		right_light.hide()

	clock.six_am_reached.connect(night_done)
	clock.hour_passed.connect(_on_hour_passed)

	for node: Node in get_tree().get_nodes_in_group(LightButton.GROUP):
		var button := node as LightButton
		if button != null:
			button.pressed.connect(_on_light_button_pressed)

	for node: Node in get_tree().get_nodes_in_group(DoorButton.GROUP):
		var button := node as DoorButton
		if button != null:
			button.pressed.connect(_on_door_button_pressed)

	if hud != null:
		hud.monitor_requested.connect(toggle_monitor)
		hud.quit_confirmed.connect(quit_to_menu)

	if power_system != null:
		if hud != null:
			power_system.power_changed.connect(hud.set_power)
		power_system.power_depleted.connect(_on_power_depleted)
		var doors: Array[Door] = [left_door, right_door]
		var lights: Array[DoorLight] = [left_light, right_light]
		power_system.start(difficulty, doors, lights, player)

	for animatronic: AnimatronicBase in animatronics:
		if animatronic == null:
			continue
		if difficulty.get_profile(animatronic.id) == null:
			push_warning("Night: no AI profile for animatronic '%s' (id '%s'), AI level stays 0." % [animatronic.name, animatronic.id])
		animatronic.ai_level = difficulty.base_ai_for(animatronic.id)
		animatronic.reached_office.connect(trigger_game_over.bind(animatronic))
		animatronic.place_at_start()

	if hud != null and not difficulty.hint_detail.is_empty():
		hud.show_hint(difficulty.hint_title, difficulty.hint_detail)

	await get_tree().create_timer(AI_START_DELAY, false).timeout
	if not is_inside_tree() or game_over or night_complete:
		return
	for animatronic: AnimatronicBase in animatronics:
		if animatronic != null:
			animatronic.start_ai()


func _unhandled_input(event: InputEvent) -> void:
	if night_complete:
		return
	if event.is_action_pressed("toggle_monitor"):
		toggle_monitor()
		return
	if game_over:
		return
	if event.is_action_pressed("left_door"):
		toggle_left_door()
	elif event.is_action_pressed("right_door"):
		toggle_right_door()
	elif event.is_action_pressed("left_light"):
		toggle_left_light()
	elif event.is_action_pressed("right_light"):
		toggle_right_light()


func can_use_office_controls() -> bool:
	return (power_system == null or power_system.has_power()) and (player == null or not player.is_monitor_on())


func toggle_door(door: Door) -> void:
	if door != null and can_use_office_controls():
		door.toggle()


func toggle_light(light: DoorLight) -> void:
	if light != null and can_use_office_controls():
		light.visible = not light.visible


func toggle_left_door() -> void:
	toggle_door(left_door)


func toggle_right_door() -> void:
	toggle_door(right_door)


func toggle_left_light() -> void:
	toggle_light(left_light)


func toggle_right_light() -> void:
	toggle_light(right_light)


func toggle_monitor() -> void:
	if night_complete or player == null:
		return
	if game_over and not player.is_monitor_on():
		return
	if power_system == null or power_system.has_power():
		player.toggle_monitor()


func trigger_game_over(animatronic: AnimatronicBase) -> void:
	if game_over or night_complete or animatronic == null:
		return
	game_over = true
	if hud != null:
		hud.hide_quit_button()
		hud.hide_hint()
	_stop_animatronics()
	if power_system != null:
		power_system.stop()
	if left_door != null:
		left_door.force_open()
	if right_door != null:
		right_door.force_open()

	if player != null:
		player.lock_view()
		if animatronic.forces_monitor_down:
			player.force_monitor_down()

		var wait_elapsed: float = 0.0
		while (player.is_monitor_on() or player.monitor.refuse_requests) and wait_elapsed < MONITOR_WAIT_TIMEOUT:
			await get_tree().process_frame
			if not is_inside_tree():
				return
			wait_elapsed += get_process_delta_time()

	await get_tree().create_timer(0.25, false).timeout
	if not is_inside_tree():
		return

	if animatronic.jumpscare == null:
		push_error("Night: animatronic '%s' has no jumpscare assigned." % animatronic.name)
		return

	if player != null:
		player.snap_view_to_center()
	for map_animatronic: AnimatronicBase in animatronics:
		if map_animatronic != null:
			map_animatronic.hide()
	animatronic.jumpscare.play_jumpscare()


func night_done() -> void:
	if game_over:
		return
	night_complete = true
	SaveManager.complete_night(Global.current_night)
	_stop_animatronics()
	if power_system != null:
		power_system.stop()
	var err := get_tree().change_scene_to_file(SCENE_SIX_AM)
	if err != OK:
		push_error("Night: Failed to change scene to '%s' (Error %d)" % [SCENE_SIX_AM, err])


## Abandons the night without saving progress; the tree must be unpaused or the menu would load frozen.
func quit_to_menu() -> void:
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(SCENE_MAIN_MENU)
	if err != OK:
		push_error("Night: Failed to change scene to '%s' (Error %d)" % [SCENE_MAIN_MENU, err])


func _stop_animatronics() -> void:
	for animatronic: AnimatronicBase in animatronics:
		if animatronic != null:
			animatronic.stop_ai()


func _pick_difficulty() -> NightDifficulty:
	if difficulties.is_empty():
		return null
	return difficulties[clampi(Global.current_night, 1, difficulties.size()) - 1]


func _on_light_button_pressed(side: String) -> void:
	if game_over or night_complete:
		return
	toggle_light(left_light if side == "Left" else right_light)


func _on_door_button_pressed(side: String) -> void:
	if game_over or night_complete:
		return
	toggle_door(left_door if side == "Left" else right_door)


func _on_hour_passed() -> void:
	if clock == null or difficulty == null:
		return
	var hour: int = clock.current_hour
	for animatronic: AnimatronicBase in animatronics:
		if animatronic != null:
			var amount := difficulty.bonus_for_hour(animatronic.id, hour)
			animatronic.ai_level = clampi(animatronic.ai_level + amount, 0, AnimatronicBase.MAX_AI_LEVEL)


func _on_power_depleted() -> void:
	if left_door != null:
		left_door.force_open()
	if right_door != null:
		right_door.force_open()
	if hud != null:
		hud.show_power_out()
	if player != null:
		player.force_monitor_down()
