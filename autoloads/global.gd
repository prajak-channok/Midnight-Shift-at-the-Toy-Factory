extends Node

const WEB_LOCK_LANDSCAPE_JS := "(function(){var l=function(){try{screen.orientation.lock('landscape').catch(function(){});}catch(e){}};l();document.addEventListener('fullscreenchange',l,{once:true});})();" ## โค้ด JavaScript ล็อคหน้าจอแนวนอนบนเว็บบราวเซอร์เมื่อเข้าสู่โหมดเต็มจอ (Lock screen orientation to landscape on web browsers when fullscreen)

var current_night = 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


## สลับโหมดเต็มจอและล็อคแนวนอนไว้เสมอสำหรับอุปกรณ์พกพา (Toggle fullscreen and keep landscape orientation for mobile)
func toggle_fullscreen() -> void:
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WEB_LOCK_LANDSCAPE_JS)


func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func is_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Master"))


func toggle_mute() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), not is_muted())
