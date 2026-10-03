extends OmniLight3D
class_name VentLight

@onready var light_sound = $LightSound


func _on_visibility_changed():
	if visible:
		light_sound.play()
	else:
		light_sound.stop()


func is_turned_on() -> bool:
	return self.visible
