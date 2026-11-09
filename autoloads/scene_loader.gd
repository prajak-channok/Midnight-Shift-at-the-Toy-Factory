extends Node

var _loading_overlay: LoadingOverlay


func change_scene(path: String, use_loading_screen: bool = true) -> void:
	if not use_loading_screen:
		get_tree().change_scene_to_file(path)
		return

	_show_loading()
	await get_tree().process_frame
	await get_tree().process_frame

	var scene: PackedScene = null
	if ResourceLoader.load_threaded_request(path) == OK:
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		scene = ResourceLoader.load_threaded_get(path) as PackedScene

	if _loading_overlay != null and is_instance_valid(_loading_overlay):
		_loading_overlay.make_opaque()

	if scene != null:
		get_tree().change_scene_to_packed(scene)
	else:
		get_tree().change_scene_to_file(path)


func _show_loading() -> void:
	if _loading_overlay != null and is_instance_valid(_loading_overlay):
		_loading_overlay.queue_free()
	_loading_overlay = LoadingOverlay.new()
	add_child(_loading_overlay)


func dismiss_loading() -> void:
	if _loading_overlay != null and is_instance_valid(_loading_overlay):
		_loading_overlay.queue_free()
		_loading_overlay = null
	LoadingOverlay.dismiss(get_tree())
