extends Resource
class_name NightDifficulty
## Per-night tuning: animatronic AI and power drain. One .tres per night.

@export_group("Animatronic AI")
@export_range(0, 20) var blue_ai: int = 4
@export_range(0, 20) var yellow_ai: int = 3
@export var hour_bonus: int = 2 ## AI added when an hour in the lists below is reached.
@export var blue_bonus_hours: Array[int] = []
@export var yellow_bonus_hours: Array[int] = []

@export_group("Power drain per second")
@export var base_drain: float = 0.10
@export var door_drain: float = 0.12 ## Per closed door.
@export var monitor_drain: float = 0.04
@export var light_drain: float = 0.0 ## Per vent light turned on.


func blue_bonus_for_hour(hour: int) -> int:
	return hour_bonus if hour in blue_bonus_hours else 0


func yellow_bonus_for_hour(hour: int) -> int:
	return hour_bonus if hour in yellow_bonus_hours else 0
