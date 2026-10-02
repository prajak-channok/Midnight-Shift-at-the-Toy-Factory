extends Node
class_name PowerSystem

signal power_changed(percent: int)
signal power_depleted

var power: float = 100.0

var _difficulty: NightDifficulty
var _doors: Array[FnafDoor] = []
var _vent_lights: Array[VentLight] = []
var _player: Player
var _running: bool = false
var _last_percent: int = -1


func start(difficulty: NightDifficulty, doors: Array[FnafDoor], vent_lights: Array[VentLight], player: Player) -> void:
	_difficulty = difficulty
	_doors = doors
	_vent_lights = vent_lights
	_player = player
	_running = true
	_emit_percent()


func stop() -> void:
	_running = false


func has_power() -> bool:
	return power > 0.0


func _process(delta: float) -> void:
	if not _running:
		return

	power = maxf(0.0, power - _drain_rate() * delta)
	_emit_percent()

	if power <= 0.0:
		_running = false
		power_depleted.emit()


func _drain_rate() -> float:
	var rate: float = _difficulty.base_drain
	for door in _doors:
		if door.is_closed:
			rate += _difficulty.door_drain
	for light in _vent_lights:
		if light.is_turned_on():
			rate += _difficulty.light_drain
	if _player.is_monitor_on():
		rate += _difficulty.monitor_drain
	return rate


func _emit_percent() -> void:
	var percent: int = int(power)
	if percent != _last_percent:
		_last_percent = percent
		power_changed.emit(percent)
