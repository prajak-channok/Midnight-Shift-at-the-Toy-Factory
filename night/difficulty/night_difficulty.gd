extends Resource
class_name NightDifficulty

@export_group("Animatronic AI")
@export var hour_bonus: int = 2 ## ระดับ AI ที่จะเพิ่มขึ้นเมื่อถึงชั่วโมงโบนัส (AI level added when bonus hour is reached)
@export var ai_profiles: Array[AnimatronicAIProfile] = []

@export_group("Power drain per second")
@export var base_drain: float = 0.10
@export var door_drain: float = 0.12 ## อัตราใช้พลังงานต่อวินาทีต่อหนึ่งประตูที่ปิด (Power drain per second per closed door)
@export var monitor_drain: float = 0.04
@export var light_drain: float = 0.0 ## อัตราใช้พลังงานต่อวินาทีต่อหนึ่งไฟประตูที่เปิด (Power drain per second per active door light)

@export_group("Night Hint")
@export var hint_title: String = "" ## หัวข้อคำใบ้ตอนเริ่มคืน (Hint title at the start of the night)
@export var hint_detail: String = "" ## รายละเอียดคำใบ้ตอนเริ่มคืน หากเว้นว่างไว้จะไม่แสดง (Hint detail at night start, hidden if empty)


## คืนค่าโปรไฟล์ AI ของหุ่น หรือ null หากไม่มีในคืนนี้ (Return animatronic AI profile or null if absent this night)
func get_profile(animatronic_id: StringName) -> AnimatronicAIProfile:
	for profile in ai_profiles:
		if profile.animatronic_id == animatronic_id:
			return profile
	return null


func base_ai_for(animatronic_id: StringName) -> int:
	var profile := get_profile(animatronic_id)
	return profile.base_ai if profile else 0


func bonus_for_hour(animatronic_id: StringName, hour: int) -> int:
	var profile := get_profile(animatronic_id)
	return hour_bonus if profile and hour in profile.bonus_hours else 0
