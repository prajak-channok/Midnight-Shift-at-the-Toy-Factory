extends FnafAnimatronic
class_name BurnedPlushBot
## Burned Plush-Bot: a half-melted plastic teddy possessed by a ghost.
## It cannot move while a camera is looking at it at one of [member frozen_when_watched_at].
## Everywhere else it moves normally. The door is optional:
## with one it attacks through it, without one it walks straight into the office.[br]
## On nights listed in [constant LURE_COOLDOWN_BY_NIGHT] the camera monitor's "play audio" button can lure it.
## A lure only matters at its next successful movement opportunity: if the lured room is one it can walk to
## from where it stands, it goes there instead of rolling a random destination. Otherwise it is ignored.
## Either way the lure is used up.

## Night number -> seconds the "play audio" button needs to recharge. Nights missing here have no button.
const LURE_COOLDOWN_BY_NIGHT := {
	2: 30.0,
	3: 25.0,
	4: 20.0,
	5: 15.0,
}

@export var frozen_when_watched_at: Array[StringName] = [&"RightHall"] ## Positions where a camera on the plush-bot holds it in place.

var _lure_room: StringName = &""


func start_ai() -> void:
	_setup_audio_lure()
	super()


## Remembers the room the player played audio in (an AnimatronicPosition name).
func lure_to(room: StringName) -> void:
	_lure_room = room


func _can_attempt_move() -> bool:
	var here := current_position.name
	return not (here in frozen_when_watched_at and cam_manager.is_watching(here))


func _pick_destination() -> StringName:
	var lured := _lure_room
	_lure_room = &""
	if lured != &"" and graph.can_move(current_position.name, lured):
		return lured
	return super()


func _on_reach_office() -> void:
	if door == null:
		_enter_office()
	else:
		await _attack_through_door()


func _setup_audio_lure() -> void:
	var cooldown: float = LURE_COOLDOWN_BY_NIGHT.get(Global.current_night, 0.0)
	if cooldown <= 0.0 or cam_manager == null:
		return
	cam_manager.setup_audio_lure(cooldown)
	if not cam_manager.audio_lure_requested.is_connected(lure_to):
		cam_manager.audio_lure_requested.connect(lure_to)
