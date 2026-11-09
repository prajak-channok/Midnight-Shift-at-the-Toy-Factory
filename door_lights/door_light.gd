extends OmniLight3D
class_name DoorLight

@onready var light_sound: AudioStreamPlayer3D = $LightSound


func _on_visibility_changed() -> void:
	if visible:
		light_sound.play()
	else:
		light_sound.stop()


func is_turned_on() -> bool:
	return self.visible
