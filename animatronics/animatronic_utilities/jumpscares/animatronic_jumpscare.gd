@tool
extends Node3D
class_name AnimatronicJumpscare
## Jumpscare player node.
##
## This node can play a jumpscare animation and changes the scene to the game over scene afterwards.
## [br]Requires a model (Node3D node with an animationplayer as a child) to work.
## [br]You can also optionally add a AudioStreamPlayer as a child of this node to play a jumpscare sound (or just modify the animation to play audio).


@export var jumpscare_anim_name := "jumpscare"
@export var scene_to_go_after : PackedScene = preload("res://game_over/game_over.tscn")
@export var audio_delay: float = 0.0
## Rotates the jumpscare around the player camera so it plays in front of wherever the player is looking.
@export var face_camera_yaw: bool = false
@export var test_jumpscare: bool = false:
	set(value):
		play_jumpscare()

var model : Node3D
var model_anim : AnimationPlayer

@onready var audio : AudioStreamPlayer = $AudioStreamPlayer as AudioStreamPlayer


func _ready():
	for c in get_children():
		if c is AudioStreamPlayer:
			audio = c as AudioStreamPlayer
	
	for c in get_children():
		if c is Node3D:
			model = c as Node3D
			break
	if model:
		model_anim = model.get_node("AnimationPlayer") as AnimationPlayer
	if model_anim:
		model.hide()
	else:
		printerr(self.name + " does not have a child animated model.")


func play_jumpscare():
	if not model_anim:
		return
	if face_camera_yaw and not Engine.is_editor_hint():
		_align_to_camera()
	if audio:
		_play_audio()
	model_anim.play(jumpscare_anim_name)
	await get_tree().process_frame
	model.show()
	await model_anim.animation_finished
	model.hide()
	if not Engine.is_editor_hint():
		get_tree().change_scene_to_file("res://game_over/game_over.tscn")


func _play_audio() -> void:
	if audio_delay > 0.0:
		await get_tree().create_timer(audio_delay).timeout
	audio.play()


func _align_to_camera() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var pivot := cam.global_position
	var yaw_basis := Basis(Vector3.UP, cam.global_rotation.y)
	global_transform = Transform3D(yaw_basis, pivot) * Transform3D(Basis.IDENTITY, -pivot) * global_transform
