@tool
extends Node3D
class_name AnimatronicJumpscare

@export var jumpscare_anim_name := "jumpscare"
@export var scene_to_go_after : PackedScene = preload("res://game_over/game_over.tscn")
@export var audio_delay: float = 0.0
@export var test_jumpscare: bool = false: ## สวิตช์สำหรับกดทดสอบจัมป์สแกร์ใน Inspector (Toggle to preview jumpscare in inspector)
	set(value):
		play_jumpscare()

var model : Node3D
var model_anim : AnimationPlayer

@onready var audio : AudioStreamPlayer = $AudioStreamPlayer as AudioStreamPlayer


func _ready() -> void:
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


func play_jumpscare() -> void:
	if not model_anim:
		return
	if audio:
		_play_audio()
	model_anim.play(jumpscare_anim_name)
	await get_tree().process_frame # รอหนึ่งเฟรมเพื่อให้อนิเมชันเริ่มก่อนแสดงโมเดล (Wait one frame for animation to start before showing model)
	model.show()
	await model_anim.animation_finished
	model.hide()
	if not Engine.is_editor_hint():
		get_tree().change_scene_to_file("res://game_over/game_over.tscn")


func _play_audio() -> void:
	if audio_delay > 0.0:
		await get_tree().create_timer(audio_delay).timeout
	audio.play()
