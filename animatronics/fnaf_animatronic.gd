extends TravellingAnimatronic
class_name FnafAnimatronic
## Walks the AnimatronicGraph assigned in [member graph]. The position names in the graph
## must match the AnimatronicPosition markers in the positions container.
## When the graph picks "Office" the animatronic attacks through [member door].

@export var graph: AnimatronicGraph
@export var door: Door
@export var night: Night

var active: bool = false


func start_ai() -> void:
	if graph == null:
		push_error("%s: no AnimatronicGraph assigned." % name)
		return
	if not _graph_has_all_markers():
		return

	active = true
	move_to_pos(graph.start_position)

	while active:
		await wait_for_successful_movement_opportunity(graph.decision_time_min, graph.decision_time_max)
		if not active:
			return

		var destination := graph.pick_destination(current_position.name)
		if destination == AnimatronicGraph.OFFICE:
			await _attack_office()
		elif destination != &"":
			move_to_pos(destination)


func stop_ai() -> void:
	active = false
	stop_movement()


func _attack_office() -> void:
	if door.is_closed:
		await wait_seconds(randf_range(graph.blocked_retreat_delay_min, graph.blocked_retreat_delay_max))
		if not active:
			return
		if door.is_closed:
			move_to_pos(graph.start_position)
			return

	active = false
	night.trigger_game_over(self)


func _graph_has_all_markers() -> bool:
	var valid := true
	for pos_name in graph.get_all_position_names():
		if animatronic_positions_container.get_position_by_name(pos_name) == null:
			push_error("%s: graph position '%s' has no marker in its positions container." % [name, pos_name])
			valid = false
	return valid
