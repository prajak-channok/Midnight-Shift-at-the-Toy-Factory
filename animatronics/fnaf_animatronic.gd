extends TravellingAnimatronic
class_name FnafAnimatronic
## Walks through the positions of its AnimatronicPositionsContainer (in node order).
## The last position is the vent next to its door; from there it attacks if the door is open.

@export var door: Door
@export var night: Night

var active: bool = false


func start_ai() -> void:
	var positions: Array[AnimatronicPosition] = animatronic_positions_container.get_array_of_positions()
	if positions.size() < 2:
		return

	active = true
	var first_pos: AnimatronicPosition = positions[0]
	var final_pos: AnimatronicPosition = positions[positions.size() - 1]
	move_to_pos(first_pos.name)

	while active:
		await travel_from_pos_to_pos(current_position.name, final_pos.name)
		if active:
			await _attack_door()


func stop_ai() -> void:
	active = false
	stop_movement()


func _attack_door() -> void:
	await wait_for_successful_movement_opportunity()
	if not active:
		return

	if door.is_closed:
		await wait_seconds(randf_range(2.0, 4.0))
		if not active:
			return
		if door.is_closed:
			move_to_pos(current_position.get_previous_position().name)
			return

	active = false
	night.trigger_game_over(self)
