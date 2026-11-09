extends Resource
class_name AnimatronicAIProfile

@export var animatronic_id: StringName ## ต้องตรงกับ id ของ AnimatronicBase (Must match AnimatronicBase id)
@export_range(0, 20) var base_ai: int = 0 ## ระดับ AI เริ่มต้นของหุ่นในคืนนี้ (Initial AI level for this night)
@export var bonus_hours: Array[int] = [] ## ชั่วโมงที่จะเพิ่มระดับ AI ตามโบนัสชั่วโมง (Hours when hourly AI bonus is added)

