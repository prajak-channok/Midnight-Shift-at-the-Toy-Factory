extends Area3D
class_name LightButton

signal pressed(side: String)

const GROUP := "light_buttons"

@export_enum("Left", "Right") var side: String = "Left"


func _ready() -> void:
	add_to_group(GROUP)


func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(side)
