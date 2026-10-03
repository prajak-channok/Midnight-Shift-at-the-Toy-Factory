extends Node3D

var monitor_on: bool = false
var refuse_requests: bool = false

@onready var anim: AnimationPlayer = $AnimationPlayer


func turn_on():
	if refuse_requests:
		return
	
	refuse_requests = true
	anim.play("slam_into_face")
	monitor_on = true
	await anim.animation_finished
	refuse_requests = false
	

func turn_off():
	if refuse_requests:
		return
	
	refuse_requests = true
	anim.play("put_back_down")
	monitor_on = false
	await anim.animation_finished
	refuse_requests = false
