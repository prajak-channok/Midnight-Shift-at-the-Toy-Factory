extends FnafAnimatronic
class_name FreddyAnimatronic
## Freddy cannot move while a camera is looking at him at one of [member frozen_when_watched_at].
## Everywhere else he moves normally. The door is optional:
## with one he attacks through it, without one he walks straight into the office.

@export var frozen_when_watched_at: Array[StringName] = [&"RightVent"] ## Positions where a camera on Freddy holds him in place.


func _can_attempt_move() -> bool:
	var here := current_position.name
	return not (here in frozen_when_watched_at and cam_manager.is_watching(here))


func _on_reach_office() -> void:
	if door == null:
		_enter_office()
	else:
		await _attack_through_door()
