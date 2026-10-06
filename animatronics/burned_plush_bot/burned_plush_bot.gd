extends FnafAnimatronic
class_name BurnedPlushBot
## Burned Plush-Bot: a half-melted plastic teddy possessed by a ghost.
## It cannot move while a camera is looking at it at one of [member frozen_when_watched_at].
## Everywhere else it moves normally. The door is optional:
## with one it attacks through it, without one it walks straight into the office.
## Each time it arrives somewhere it strikes a random pose from [member pose_animations].

@export var frozen_when_watched_at: Array[StringName] = [&"RightVent"] ## Positions where a camera on the plush-bot holds it in place.
@export var pose_animations: Array[StringName] = [&"normal", &"slump", &"stare", &"reach"] ## Poses picked at random on arrival.
@export var fixed_pose_positions: Array[StringName] = [&"RightVent"] ## Positions that always use their own AnimatronicPosition animation (the vent is too low to stand in).

var _last_pose: StringName = &""


func apply_position_to_body(pos: AnimatronicPosition) -> void:
	global_transform = pos.global_transform
	if _animation_player == null:
		return
	var anim := StringName(pos.animation_to_play)
	if not fixed_pose_positions.has(pos.name):
		anim = _pick_pose()
	if _animation_player.has_animation(anim):
		_animation_player.play(anim)


func _can_attempt_move() -> bool:
	var here := current_position.name
	return not (here in frozen_when_watched_at and cam_manager.is_watching(here))


func _on_reach_office() -> void:
	if door == null:
		_enter_office()
	else:
		await _attack_through_door()


func _pick_pose() -> StringName:
	if pose_animations.is_empty():
		return &"normal"
	var choices: Array = pose_animations.filter(func(pose: StringName) -> bool: return pose != _last_pose)
	if choices.is_empty():
		choices = pose_animations
	_last_pose = choices.pick_random()
	return _last_pose
