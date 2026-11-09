extends Control

func _on_animation_player_animation_finished():
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
