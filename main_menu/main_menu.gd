extends Control

@onready var night_buttons: Control = %NightButtons


func _ready() -> void:
	for i in night_buttons.get_child_count():
		var button := night_buttons.get_child(i) as Button
		button.pressed.connect(start_night.bind(i + 1))


func start_night(night: int) -> void:
	Global.current_night = night
	get_tree().change_scene_to_file("res://night/night.tscn")
