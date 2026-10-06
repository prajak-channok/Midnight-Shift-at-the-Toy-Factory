extends Node

## Browsers only allow the orientation lock while fullscreen, and fullscreen is entered asynchronously, so retry once it changes.
const WEB_LOCK_LANDSCAPE_JS := "(function(){var l=function(){try{screen.orientation.lock('landscape').catch(function(){});}catch(e){}};l();document.addEventListener('fullscreenchange',l,{once:true});})();"

var current_night = 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


## Landscape is never released again: the game is only playable that way, so leaving fullscreen keeps it.
func toggle_fullscreen() -> void:
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

	if _is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WEB_LOCK_LANDSCAPE_JS)


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
