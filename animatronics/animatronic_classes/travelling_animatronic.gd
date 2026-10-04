extends AnimatronicBase
class_name TravellingAnimatronic
## Base class for animatronics that travel around the map.
##
## You can make your animatronic script extend this class to facilitate
## the process of making your animatronic move around.[br]
## Check out the code for one of the animatronics extending this class to get an idea of how you can use it.


@export var animatronic_positions_container : AnimatronicPositionsContainer ## A link to the animatronic's positions container. It will provide us with positions that the animatronic can go to.
@export var cam_manager : CameraManager ## A link to the camera manager (to be able to make the monitor lose communication when the animatronic moves).
@export var animation_player_path : NodePath ## A path to the model's [AnimationPlayer] node (so we can play different pose animations at different positions).

var _animation_player : AnimationPlayer
var _stopped := false
var current_position : AnimatronicPosition ## The [AnimatronicPosition] that the animatronic is currently at.


func _ready():
	_animation_player = get_node(animation_player_path)


## Makes the animatronic directly move to the specified position name.
func move_to_pos(pos_name : String):
	var pos: AnimatronicPosition = animatronic_positions_container.get_position_by_name(pos_name)
	cam_manager.lose_communication(0.2)
	current_position = pos
	apply_position_to_body(current_position)


## Physically teleports the animatronic to an [AnimatronicPosition]
## and applies its [param animation_to_play] property if it is a valid animation name.
func apply_position_to_body(pos : AnimatronicPosition):
	global_transform = pos.global_transform
	if _animation_player and _animation_player.has_animation(pos.animation_to_play):
		_animation_player.play(pos.animation_to_play)


## This function ends once a movement opportunity is successful.
## Opportunities happen every random [param min_wait]..[param max_wait] seconds.[br]
## Use the "await" keyword to wait until the function is done before making the animatronic do something else.
func wait_for_successful_movement_opportunity(min_wait: float, max_wait: float):
	while not _stopped:
		await wait_seconds(randf_range(min_wait, max_wait))
		if ai_level >= randi_range(1,MAX_AI_LEVEL):
			break


## Stops all pending and future movement. Waiting functions return immediately afterwards.
func stop_movement() -> void:
	_stopped = true


## Waits using a timer owned by this node, so freeing the animatronic cancels the wait
## instead of resuming a coroutine whose instance is gone.
func wait_seconds(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()
