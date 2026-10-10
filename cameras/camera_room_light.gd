extends OmniLight3D
class_name CameraRoomLight
## Light that is only on while the camera named [member camera_name] is being watched.

@export var camera_name: StringName
@export var cam_manager: CameraManager


func _process(_delta: float) -> void:
	visible = cam_manager != null and cam_manager.is_watching(camera_name)
