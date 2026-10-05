extends TravellingAnimatronic
class_name FnafAnimatronic
## Walks the AnimatronicGraph assigned in [member graph]. The position names in the graph
## must match the AnimatronicPosition markers in the positions container.
## When the graph picks "Office" the animatronic tries to get in; what happens then is decided by
## [method _on_reach_office].[br]
## Subclasses customise the walk by overriding the hooks:
## [method _can_attempt_move], [method _on_reach_office], [method _get_return_position] and [method _validate_setup].

@export var graph: AnimatronicGraph
@export var door: Door ## Optional. Only used by [method _attack_through_door]; subclasses decide whether it is required.

var active: bool = false


func start_ai() -> void:
	if graph == null:
		push_error("%s: no AnimatronicGraph assigned." % name)
		return
	if not _validate_setup():
		return

	active = true
	move_to_pos(graph.start_position)

	while active:
		await wait_for_successful_movement_opportunity(graph.decision_time_min, graph.decision_time_max)
		if not active:
			return
		if not _can_attempt_move():
			continue

		var destination := graph.pick_destination(current_position.name)
		if destination == AnimatronicGraph.OFFICE:
			await _on_reach_office()
		elif destination != &"":
			move_to_pos(destination)


func stop_ai() -> void:
	active = false
	stop_movement()


## Hook: return false to skip this movement opportunity (e.g. Freddy while a camera is watching him).
func _can_attempt_move() -> bool:
	return true


## Hook: called when the graph picks the reserved Office destination. The default walks straight in.
func _on_reach_office() -> void:
	_enter_office()


## Hook: where the animatronic retreats to when it is blocked.
func _get_return_position() -> StringName:
	return graph.get_return_position()


## Hook: check the scene wiring before the AI starts. Return false to keep the AI off.
func _validate_setup() -> bool:
	return _graph_has_all_markers()


## The animatronic got in: the night is lost.
func _enter_office() -> void:
	active = false
	reached_office.emit()


## Door rule: an open [member door] lets the animatronic in. A closed one holds it for a random delay;
## if the door is still closed afterwards the animatronic retreats to [method _get_return_position].
func _attack_through_door() -> void:
	if door.is_closed:
		await wait_seconds(randf_range(graph.blocked_retreat_delay_min, graph.blocked_retreat_delay_max))
		if not active:
			return
		if door.is_closed:
			move_to_pos(_get_return_position())
			return

	_enter_office()


func _graph_has_all_markers() -> bool:
	var valid := true
	for pos_name in graph.get_all_position_names():
		if animatronic_positions_container.get_position_by_name(pos_name) == null:
			push_error("%s: graph position '%s' has no marker in its positions container." % [name, pos_name])
			valid = false
	return valid
