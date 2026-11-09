extends Node3D
class_name Monitor

var monitor_on: bool = false
var refuse_requests: bool = false ## ล็อคไม่ให้รับคำสั่งเปิดปิดมอนิเตอร์ซ้ำขณะที่อนิเมชันกำลังเล่นอยู่ (Refuse toggle requests while animation is playing)

@onready var anim: AnimationPlayer = $AnimationPlayer


func turn_on() -> void:
	if refuse_requests:
		return
	
	refuse_requests = true
	anim.play("slam_into_face")
	monitor_on = true
	await anim.animation_finished
	refuse_requests = false
	

func turn_off() -> void:
	if refuse_requests:
		return
	
	refuse_requests = true
	anim.play("put_back_down")
	monitor_on = false
	await anim.animation_finished
	refuse_requests = false
