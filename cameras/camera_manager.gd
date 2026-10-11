extends Node
class_name CameraManager
## Camera Manager node
##
## This node manages a bunch of Camera3D nodes and keeps in its scene a Camera UI
## that contains a bunch of camera buttons to allow the player to switch between cameras.

const DEFAULT_CAM_INDEX = 0

## Parent of the room lights. A light belongs to the camera whose node name its own name starts with
## (e.g. "ToyFactoryRimLight" -> "ToyFactory") and is only shown while that camera is being watched.
## Lights that match no camera are left untouched.
@export var lights_root: Node3D
## Cameras whose lights stay on even when the monitor is down because they are visible from the office.
@export var always_lit_cams: PackedStringArray = ["LeftHall", "RightHall"]

var selected_cam : Camera3D
var all_cams = {}
var cam_lights = {}	# Camera3D name -> Array[Light3D]

@onready var cam_ui = $%CameraUI
@onready var cam_buttons_parent = $%CamButtonsParent
@onready var cam_click_sound = $CamClickSound
@onready var ui_animation_player = $CameraUI/AnimationPlayer


func _ready():
	cam_ui.visible = false
	
	# Add all cameras to the camera dictionary
	# Each key is the name of the camera in lowercase and the value is a reference to the Camera3D node.
	for c in get_children():
		if c is Camera3D:
			all_cams[c.name.to_lower()] = c
			c.current = false
	
	# Connect the cam_button_pressed signal from each camera button
	# to the set_current_cam function
	for c in cam_buttons_parent.get_children():
		if c is BaseButton:
			c.connect("cam_button_pressed", set_current_cam)
	
	# Set default cam
	if not all_cams.values().is_empty():
		selected_cam = all_cams.values()[DEFAULT_CAM_INDEX]
	else:
		printerr("no cameras are under camera manager")

	_collect_cam_lights()
	_update_lights()


func _collect_cam_lights():
	if lights_root == null:
		return
	for light in lights_root.get_children():
		if not light is Light3D:
			continue
		for cam_name in all_cams.values().map(func(c): return String(c.name)):
			if String(light.name).begins_with(cam_name):
				if not cam_lights.has(cam_name):
					cam_lights[cam_name] = []
				cam_lights[cam_name].append(light)
				break


## Only the lights of the watched camera (plus the always lit ones) are rendered, so the number
## of lights hitting the big building mesh stays under the Compatibility renderer's per-object cap.
func _update_lights():
	for cam_name in cam_lights:
		var lit : bool = cam_name in always_lit_cams \
			or (cam_ui.visible and selected_cam != null and selected_cam.name == cam_name)
		for light in cam_lights[cam_name]:
			light.visible = lit


func set_current_cam(cam : String):
	# set the previous camera as not current and hide it, switch to the new one and make that one current
	selected_cam.current = false
	selected_cam = all_cams[cam.to_lower()]
	selected_cam.current = true
	_update_lights()
	cam_click_sound.play()
	lose_communication(1.0)


func lose_communication(time_scale : float):
	ui_animation_player.stop()
	ui_animation_player.speed_scale = time_scale
	ui_animation_player.play("lost_communication")


## True while the monitor is up and the selected camera is the one named after [param position_name]
## (camera node names match AnimatronicPosition names, case-insensitive).


func is_watching(position_name : StringName) -> bool:
	return cam_ui.visible and selected_cam != null and selected_cam.name.to_lower() == String(position_name).to_lower()


func enable_camera_display():
	if selected_cam:
		selected_cam.current = true
	cam_ui.visible = true
	_update_lights()


func disable_camera_display():
	if selected_cam:
		selected_cam.current = false
	cam_ui.visible = false
	_update_lights()
