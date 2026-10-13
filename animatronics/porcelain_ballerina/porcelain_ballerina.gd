extends DoorAnimatronic
class_name PorcelainBallerina
## Porcelain Ballerina: on nights listed in [constant LURE_COOLDOWN_BY_NIGHT] the camera monitor's
## "play audio" button can lure her. A lure only matters at her next successful movement opportunity:
## if the lured room is one she can walk to from where she stands, she goes there instead of rolling
## a random destination. Otherwise it is ignored. Either way the lure is used up.

## Night number -> seconds the "play audio" button needs to recharge. Nights missing here have no button.
const LURE_COOLDOWN_BY_NIGHT := {
	3: 30.0,
	4: 20.0,
	5: 15.0,
}

var _lure_room: StringName = &""


func start_ai() -> void:
	_setup_audio_lure()
	super()


## Remembers the room the player played audio in (an AnimatronicPosition name).
func lure_to(room: StringName) -> void:
	_lure_room = room


func _pick_destination() -> StringName:
	var lured := _lure_room
	_lure_room = &""
	if lured != &"" and graph.can_move(current_position.name, lured):
		return lured
	return super()


func _setup_audio_lure() -> void:
	var cooldown: float = LURE_COOLDOWN_BY_NIGHT.get(Global.current_night, 0.0)
	if cooldown <= 0.0 or cam_manager == null:
		return
	cam_manager.setup_audio_lure(cooldown)
	if not cam_manager.audio_lure_requested.is_connected(lure_to):
		cam_manager.audio_lure_requested.connect(lure_to)
