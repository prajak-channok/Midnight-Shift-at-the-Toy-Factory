extends Resource
class_name AnimatronicAIProfile
## AI tuning of one animatronic for one night.

@export var animatronic_id: StringName ## Must match [member AnimatronicBase.id].
@export_range(0, 20) var base_ai: int = 0
@export var bonus_hours: Array[int] = [] ## Hours at which [member NightDifficulty.hour_bonus] is added to the AI level.
