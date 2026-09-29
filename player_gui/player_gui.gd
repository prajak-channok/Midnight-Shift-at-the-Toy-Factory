extends Control

@onready var night = get_parent()


func _on_left_door_pressed():
	night.toggle_left_door()


func _on_right_door_pressed():
	night.toggle_right_door()


func _on_left_light_pressed():
	night.toggle_left_light()


func _on_right_light_pressed():
	night.toggle_right_light()


func _on_camera_pressed():
	night.toggle_camera()
