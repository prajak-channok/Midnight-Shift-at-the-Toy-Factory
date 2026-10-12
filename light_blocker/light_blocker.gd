extends MeshInstance3D
class_name LightBlocker
## A thin opaque slab that seals a door or window opening of the security room.
## It is only visible while its [member light] is off, so the hall behind it stays unseen without the light.

@export var light: DoorLight


func _ready() -> void:
	if light == null:
		push_warning("LightBlocker '%s' has no light assigned." % name)
		return
	light.visibility_changed.connect(_update)
	_update()


func _update() -> void:
	visible = not light.is_turned_on()
