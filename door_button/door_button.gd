extends Area3D
class_name DoorButton

signal pressed(side: String)

const GROUP := "door_buttons"
const COLOR_ON := Color(0.2, 0.95, 0.3)
const COLOR_OFF := Color(0.6, 0.6, 0.6)

@export_enum("Left", "Right") var side: String = "Left"
@export var door: Door

@onready var label: Label3D = $Label3D


func _ready() -> void:
	add_to_group(GROUP)
	if door == null:
		push_warning("DoorButton '%s': no door assigned." % name)
		_update_label(false)
		return
	door.state_changed.connect(_update_label)
	_update_label(door.is_closed)


func _update_label(is_closed: bool) -> void:
	label.text = "ON" if is_closed else "OFF"
	label.modulate = COLOR_ON if is_closed else COLOR_OFF


func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(side)
