extends Node3D
class_name AnimatronicBase

signal reached_office

const MAX_AI_LEVEL := 20

@export var id: StringName
@export var jumpscare: AnimatronicJumpscare ## แยกโหนดเล่นจัมป์สแกร์ออกจากโหนดที่โผล่ในกล้องเพื่อให้ง่ายต่อการจัดตำแหน่ง (Jumpscare node is separate from the on-camera node for easier positioning)

var ai_level := 0
var forces_monitor_down := false

## วางตำแหน่งของหุ่นตอนเริ่มเกม ก่อน AI เริ่มทำงาน (Place the animatronic at game start, before the AI runs)
func place_at_start() -> void:
	pass


func start_ai() -> void:
	pass


func stop_ai() -> void:
	pass
