extends FnafAnimatronic
class_name DoorAnimatronic
## Animatronic that has to get through a [member door] to enter the office (Blue, Yellow).


func _on_reach_office() -> void:
	await _attack_through_door()


func _validate_setup() -> bool:
	if door == null:
		push_error("%s: a DoorAnimatronic needs a door." % name)
		return false
	return super()
