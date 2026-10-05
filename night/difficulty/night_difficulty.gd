extends Resource
class_name NightDifficulty
## Per-night tuning: animatronic AI and power drain. One .tres per night.

@export_group("Animatronic AI")
@export var hour_bonus: int = 2 ## AI added when an hour in a profile's bonus_hours is reached.
@export var ai_profiles: Array[AnimatronicAIProfile] = []

@export_group("Power drain per second")
@export var base_drain: float = 0.10
@export var door_drain: float = 0.12 ## Per closed door.
@export var monitor_drain: float = 0.04
@export var light_drain: float = 0.0 ## Per vent light turned on.


## Returns null if the animatronic has no profile this night.
func get_profile(animatronic_id: StringName) -> AnimatronicAIProfile:
	for profile in ai_profiles:
		if profile.animatronic_id == animatronic_id:
			return profile
	return null


func base_ai_for(animatronic_id: StringName) -> int:
	var profile := get_profile(animatronic_id)
	return profile.base_ai if profile else 0


func bonus_for_hour(animatronic_id: StringName, hour: int) -> int:
	var profile := get_profile(animatronic_id)
	return hour_bonus if profile and hour in profile.bonus_hours else 0
