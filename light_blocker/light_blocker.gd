extends MeshInstance3D
class_name LightBlocker

@export var light: DoorLight ## หลอดไฟที่ควบคุมการแสดงผลของแผ่นบังสายตานี้ (Light that controls this blocker's visibility)



func _ready() -> void:
	if light == null:
		push_warning("LightBlocker '%s' has no light assigned." % name)
		return
	light.visibility_changed.connect(_update)
	_update()


func _update() -> void:
	visible = not light.is_turned_on()
