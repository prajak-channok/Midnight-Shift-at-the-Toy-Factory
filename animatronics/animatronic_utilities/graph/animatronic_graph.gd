extends Resource
class_name AnimatronicGraph

const OFFICE := &"Office"

@export var start_position: StringName ## จุดเริ่มต้นของหุ่น (Where the animatronic starts)
@export var return_position: StringName ## จุดถอยกลับของหุ่นเมื่อถูกประตูกันไว้ ถ้าเว้นว่างจะใช้ start_position (Retreat position when blocked, empty defaults to start_position)
@export_group("Timing")
@export var decision_time_min: float = 5.0 ## เวลาสุ่มรอต่ำสุดก่อนตัดสินใจเดิน (Minimum random wait time before movement opportunity)
@export var decision_time_max: float = 7.0
@export var blocked_retreat_delay_min: float = 2.0 ## เวลาที่ประตูปิดต้องกันไว้ได้ก่อนหุ่นจะยอมถอยกลับ (Hold duration a closed door must maintain before animatronic retreats)
@export var blocked_retreat_delay_max: float = 4.0
@export_group("Graph")
@export var nodes: Array[AnimatronicGraphNode] = []


## สุ่มเลือกห้องปลายทางถัดไปตามค่าน้ำหนัก (Pick next destination by weight)
func pick_destination(from: StringName) -> StringName:
	for node in nodes:
		if node.position_name != from:
			continue
		var total := 0.0
		for weight: float in node.destinations.values():
			total += weight
		if total <= 0.0:
			return &""
		var roll := randf() * total
		for destination: StringName in node.destinations:
			roll -= node.destinations[destination]
			if roll < 0.0:
				return destination
	return &""


## เช็คว่ามีเส้นทางเดินเชื่อมตรงไปยังห้องปลายทางหรือไม่ (Check if direct path exists to destination)
func can_move(from: StringName, to: StringName) -> bool:
	for node in nodes:
		if node.position_name == from:
			return node.destinations.get(to, 0.0) > 0.0
	return false


func get_return_position() -> StringName:
	return return_position if return_position != &"" else start_position


## รวมชื่อตำแหน่งทั้งหมดในกราฟ ยกเว้น Office (Get all position names in graph except Office)
func get_all_position_names() -> Array[StringName]:
	var names: Array[StringName] = [start_position, get_return_position()]
	for node in nodes:
		names.append(node.position_name)
		for destination: StringName in node.destinations:
			names.append(destination)
	var unique: Array[StringName] = []
	for pos_name in names:
		if pos_name != OFFICE and pos_name not in unique:
			unique.append(pos_name)
	return unique
