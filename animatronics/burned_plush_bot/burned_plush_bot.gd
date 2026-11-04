extends GraphAnimatronic
class_name BurnedPlushBot

const LURE_COOLDOWN_BY_NIGHT := {
	2: 30.0,
	3: 25.0,
	4: 20.0,
	5: 15.0 }

@export var frozen_when_watched_at: Array[StringName] = [&"RightHall"] ## Positions where a camera on the plush-bot holds it in place.

var _lure_room: StringName = &""


func start_ai() -> void:
	_setup_audio_lure()
	super()


## สำหรับ night ตอนกดปุ่มล่อ (Called by Night when the lure button is pressed)
func lure_to(room: StringName) -> void:
	_lure_room = room


## เงื่อนไขคือถ้าถูกกล้องดูในห้องที่กำหนด จะไม่สามารถเคลื่อนที่ได้ (Cannot move while a camera watches it in the set rooms)
func _can_attempt_move() -> bool:
	var here := current_position.name
	return not (here in frozen_when_watched_at and cam_manager.is_watching(here))


## เพิ่มลูกเล่นในการถูกล่อด้วยเสียงดนตรีได้ (Adds the lure-by-music mechanic)
func _pick_destination() -> StringName:
	var lured := _lure_room
	_lure_room = &""
	if lured != &"" and graph.can_move(current_position.name, lured): ## เช็คว่าห้องที่ล่อมีในกราฟ (Check the lured room is reachable in the graph)
		return lured
	return super()


func _setup_audio_lure() -> void:
	var cooldown: float = LURE_COOLDOWN_BY_NIGHT.get(Global.current_night, 0.0)
	if cooldown <= 0.0 or cam_manager == null:
		return
	cam_manager.setup_audio_lure(cooldown, graph.get_all_position_names())
	if not cam_manager.audio_lure_requested.is_connected(lure_to):
		cam_manager.audio_lure_requested.connect(lure_to)
