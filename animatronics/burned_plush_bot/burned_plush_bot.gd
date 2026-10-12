extends FnafAnimatronic
class_name BurnedPlushBot
## Burned Plush-Bot: a half-melted plastic teddy possessed by a ghost.
## It cannot move while a camera is looking at it at one of [member frozen_when_watched_at].
## Everywhere else it moves normally. The door is optional:
## with one it attacks through it, without one it walks straight into the office.

@export var frozen_when_watched_at: Array[StringName] = [&"RightHall"] ## Positions where a camera on the plush-bot holds it in place.


func _can_attempt_move() -> bool:
	var here := current_position.name
	return not (here in frozen_when_watched_at and cam_manager.is_watching(here))


func _on_reach_office() -> void:
	if door == null:
		_enter_office()
	else:
		await _attack_through_door()
