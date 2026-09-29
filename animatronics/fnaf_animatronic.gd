extends TravellingAnimatronic
class_name FnafAnimatronic

@export_enum("Left", "Right") var side: String = "Left"
@export var route: Array[NodePath] = []
@export var door: FnafDoor
@export var night: Node
@export var movement_interval: float = 3.5
@export_range(1, 20) var base_ai: int = 4

var current_index: int = 0
var active: bool = false


func _ready() -> void:
	super._ready()
	if not _animation_player:
		printerr(name + ": missing AnimationPlayer")


func start_ai() -> void:
	active = true
	current_index = 0
	if route.is_empty():
		return
	_apply_route_position(0)
	while active:
		var wait_time: float = movement_interval + randf_range(-0.8, 1.0)
		await get_tree().create_timer(wait_time).timeout
		if not active:
			return

		var chance: int = ai_level if ai_level > 0 else base_ai
		if randi_range(1, 20) > chance:
			continue

		if current_index >= route.size() - 2:
			await _handle_door_position()
		else:
			current_index += 1
			_apply_route_position(current_index)


func _apply_route_position(index: int) -> void:
	if index < 0 or index >= route.size():
		return
	var marker: Marker3D = get_node_or_null(route[index]) as Marker3D
	if not marker:
		return
	global_transform = marker.global_transform
	if _animation_player and _animation_player.has_animation("normal"):
		_animation_player.play("normal")


func _handle_door_position() -> void:
	if not door:
		return

	if door.is_closed:
		var block_wait: float = randf_range(2.0, 4.0)
		await get_tree().create_timer(block_wait).timeout
		if door.is_closed:
			current_index = maxi(0, route.size() - 2)
			_apply_route_position(current_index)
		else:
			await _enter_office()
	else:
		await _enter_office()


func _enter_office() -> void:
	if not door or door.is_closed:
		return

	current_index = route.size() - 1
	_apply_route_position(current_index)
	active = false

	if night and night.has_method("trigger_game_over"):
		night.trigger_game_over(self)
	elif animatronic_jumpscare:
		animatronic_jumpscare.play_jumpscare()
