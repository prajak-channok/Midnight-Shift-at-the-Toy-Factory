extends Resource
class_name AnimatronicGraphNode

@export var position_name: StringName ## ต้องตรงกับชื่อของ AnimatronicPosition (Must match name of AnimatronicPosition marker)
@export var destinations: Dictionary[StringName, float] = {} ## ห้องปลายทางพร้อมค่าน้ำหนักโอกาสเดินไป (Destination position names with movement weights)

