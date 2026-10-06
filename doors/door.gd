extends Node3D
class_name Door

signal state_changed(is_closed: bool)

@export var closed_height: float = 2
@export var open_height: float = -0.2
@export var move_time: float = 0.12

var is_closed: bool = false
var _tween: Tween

@onready var panel: MeshInstance3D = $Panel


func _ready() -> void:
	panel.position.y = open_height


func toggle() -> void:
	set_closed(not is_closed)


func set_closed(value: bool) -> void:
	if is_closed == value:
		return
	is_closed = value
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "position:y", closed_height if is_closed else open_height, move_time)
	state_changed.emit(is_closed)


func force_open() -> void:
	if is_closed:
		is_closed = false
		if _tween and _tween.is_valid():
			_tween.kill()
		panel.position.y = open_height
		state_changed.emit(false)
