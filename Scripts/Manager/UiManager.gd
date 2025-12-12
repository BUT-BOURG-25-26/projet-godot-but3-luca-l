extends Node

# UI
@export var scoreLabel: Label
@export var gameOverUI: CanvasLayer

func UpdateScore(newScore: int):
	scoreLabel.text = "SCORE : " + str(newScore)

func endOfGame(health):
	if health == 0:
		gameOverUI.visible = true
		get_tree().paused = true

func onRestartPressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func onQuitPressed() -> void:
	get_tree().quit()
