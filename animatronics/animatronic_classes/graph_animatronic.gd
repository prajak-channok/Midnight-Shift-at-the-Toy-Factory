extends AnimatronicBase
class_name GraphAnimatronic

@export var graph: AnimatronicGraph
@export var door: Door ## สำหรับหุ่นที่ประตูสามารถป้องกันได้ (For animatronics a door can block)
@export var animatronic_positions_container: AnimatronicPositionsContainer
@export var cam_manager: CameraManager ## สำหรับทำจอซ่าห์ (For lose communication)
@export var animation_player_path: NodePath

var current_position: AnimatronicPosition
var active := false ## สำหรับควบคุมลูปในการให้ AI ทำงานหรือหยุดทำ (Controls whether the AI loop runs or stops)
var _animation_player: AnimationPlayer


func _ready() -> void:
	_animation_player = get_node_or_null(animation_player_path)


func place_at_start() -> void:
	if graph == null or animatronic_positions_container == null:
		return
	var start := animatronic_positions_container.get_position_by_name(graph.start_position)
	if start == null:
		return
	current_position = start
	apply_position_to_body(start)


func start_ai() -> void:
	if graph == null:
		push_error("%s: no AnimatronicGraph assigned." % name)
		return
	if not _graph_has_all_markers():
		return

	active = true
	if current_position == null:
		move_to_pos(graph.start_position)

	while active:
		await wait_for_successful_movement_opportunity(graph.decision_time_min, graph.decision_time_max)
		if not active:
			return
		if not _can_attempt_move():
			continue

		var destination := _pick_destination()
		if destination == AnimatronicGraph.OFFICE:
			if door == null:
				_enter_office()
			else: ## ถ้าเจอประตู จะรอโจมตีอีกครั้งนึง (If there is a door, wait and attack once more)
				await _attack_through_door()
		elif destination != &"":
			move_to_pos(destination)


func stop_ai() -> void:
	active = false


## ทำจอซ่าห์เมื่อดูกล้องที่ตรงตามเงื่อนไข (Lose communication when the watched camera matches)
func move_to_pos(pos_name: StringName) -> void:
	var pos: AnimatronicPosition = animatronic_positions_container.get_position_by_name(pos_name)
	var watching_origin := current_position != null and cam_manager.is_watching(current_position.name)
	if watching_origin or cam_manager.is_watching(pos_name):
		cam_manager.lose_communication(0.2)
	current_position = pos
	apply_position_to_body(current_position)


## ย้ายตำแหน่งของโมเดล และเล่นอนิเมชันที่กำหนดไว้ (Move the model and play its assigned animation)
func apply_position_to_body(pos: AnimatronicPosition) -> void:
	global_transform = pos.global_transform
	if _animation_player and _animation_player.has_animation(pos.animation_to_play):
		_animation_player.play(pos.animation_to_play)


## สุ่มเวลาในการที่จะสุ่มว่าหุ่นจะเดินหรือไม่ ตามระดับ AI (Random wait, then roll whether it moves, based on AI level)
func wait_for_successful_movement_opportunity(min_wait: float, max_wait: float) -> void:
	while active:
		await wait_seconds(randf_range(min_wait, max_wait))
		if ai_level >= randi_range(1, MAX_AI_LEVEL):
			break
func wait_seconds(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()


## สำหรับต่อยอดในการสร้างเงื่อนไขให้หุ่นไม่สามารถเดินได้ เช่น Burned Plush Bot (Override to add conditions that block movement, e.g. Burned Plush Bot)
func _can_attempt_move() -> bool:
	return true


func _pick_destination() -> StringName:
	return graph.pick_destination(current_position.name)


func _enter_office() -> void:
	active = false
	reached_office.emit() ## ส่งสัญญาณให้ night รู้ว่าต้องแพ้แล้ว (Tell Night the player has lost)


## สุ่มเวลาในการที่จะโจมตีอีกครั้งนึงก่อนที่จะกลับจุดรีเทิร์น (Random delay before attacking again, otherwise retreat to the return position)
func _attack_through_door() -> void:
	if door.is_closed:
		await wait_seconds(randf_range(graph.blocked_retreat_delay_min, graph.blocked_retreat_delay_max))
		if not active:
			return
		if door.is_closed:
			move_to_pos(graph.get_return_position())
			return

	_enter_office()


func _graph_has_all_markers() -> bool:
	var valid := true
	for pos_name in graph.get_all_position_names():
		if animatronic_positions_container.get_position_by_name(pos_name) == null:
			push_error("%s: graph position '%s' has no marker in its positions container." % [name, pos_name])
			valid = false
	return valid
