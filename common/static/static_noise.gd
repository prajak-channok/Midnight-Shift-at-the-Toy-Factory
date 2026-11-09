extends TextureRect

# เป็นการทำอนิเมชันจอซ่าห์ด้วยโค้ด โดยไม่ใช้ AnimatedTexture เนื่องจากมีปัญหาเมื่อเรนเดอร์แบบ Compatibility ของตัวเอ็นจิน (Code-driven static noise animation avoiding AnimatedTexture on Compatibility renderer)
@export var frames: Array[Texture2D] = []
@export var frame_duration: float = 0.05

var _frame_index := 0
var _elapsed := 0.0


func _ready() -> void:
	if not frames.is_empty():
		texture = frames[0]


func _process(delta: float) -> void:
	if frames.is_empty():
		return
	_elapsed += delta
	if _elapsed >= frame_duration:
		_elapsed -= frame_duration
		_frame_index = (_frame_index + 1) % frames.size()
		texture = frames[_frame_index]
