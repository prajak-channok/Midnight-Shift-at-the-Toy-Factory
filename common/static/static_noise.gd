extends TextureRect

## Manually swaps frames instead of relying on AnimatedTexture, whose proxy-texture
## frame swap doesn't reliably refresh on the Compatibility renderer while this node's
## other properties (e.g. modulate) are being driven by an AnimationPlayer.
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
