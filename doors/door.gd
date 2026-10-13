extends Node3D
class_name Door

signal state_changed(is_closed: bool)

const SOUND_CLOSE := "res://doors/sounds/door_close.wav"
const SOUND_OPEN := "res://doors/sounds/door_open.wav"

@export var closed_height: float = 1.65
@export var open_height: float = 4.85
@export var move_time: float = 0.12
@export var sound_volume_db: float = 0.0 ## Loudness of the door sounds (negative = quieter).

var is_closed: bool = false
var _tween: Tween
var _audio: AudioStreamPlayer3D
var _close_sound: AudioStream
var _open_sound: AudioStream

@onready var panel: MeshInstance3D = $Panel


func _ready() -> void:
	panel.position.y = open_height
	_setup_audio()


func toggle() -> void:
	set_closed(not is_closed)


func set_closed(value: bool) -> void:
	if is_closed == value:
		return
	is_closed = value
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "position:y", closed_height if is_closed else open_height, move_time)
	_play(_close_sound if is_closed else _open_sound)
	state_changed.emit(is_closed)


func force_open() -> void:
	if is_closed:
		is_closed = false
		if _tween and _tween.is_valid():
			_tween.kill()
		panel.position.y = open_height
		_play(_open_sound)
		state_changed.emit(false)


# ---------- sound ----------
# The sound comes from the door itself (3D), so with headphones you hear
# the left door on the left and the right door on the right.

func _setup_audio() -> void:
	_audio = AudioStreamPlayer3D.new()
	_audio.volume_db = sound_volume_db
	_audio.unit_size = 10.0  # keeps it loud even when the door is a few metres away
	_audio.position = Vector3(0.0, closed_height, 0.0)
	add_child(_audio)
	if ResourceLoader.exists(SOUND_CLOSE):
		_close_sound = load(SOUND_CLOSE)
	if ResourceLoader.exists(SOUND_OPEN):
		_open_sound = load(SOUND_OPEN)


func _play(stream: AudioStream) -> void:
	if stream == null or _audio == null:
		return
	_audio.stream = stream
	_audio.play()
