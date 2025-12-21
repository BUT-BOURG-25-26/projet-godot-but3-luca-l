class_name StartMenu
extends CanvasLayer

func onPlayButtonPressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Gameplay.tscn")

func onQuitButtonPressed() -> void:
	get_tree().quit()
