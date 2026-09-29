extends SpotLight3D
class_name DeskFlashlight

@export var player: Node3D
@export var vent_lights: Array[Light3D]

@onready var flashlight_sound: AudioStreamPlayer3D = $FlashlightSound
@onready var disabled_timer: Timer = $DisabledTimer

var prevent_flashlight: bool = false

func _process(_delta):
	var blocked: bool = player and player.is_monitor_on()
	if Input.is_action_pressed("flashlight") and not are_vent_lights_on() and not blocked and not prevent_flashlight:
		show()
		if not flashlight_sound.playing:
			flashlight_sound.play()
	else:
		hide()
		flashlight_sound.stop()

func disable_for(time: float):
	prevent_flashlight = true
	disabled_timer.stop()
	disabled_timer.wait_time = time
	disabled_timer.start()

func are_vent_lights_on() -> bool:
	for light in vent_lights:
		if light.visible:
			return true
	return false

func _on_disabled_timer_timeout():
	prevent_flashlight = false
