class_name GameUI
extends CanvasLayer

var pauseMenu: PauseMenu
@onready var levelProgression: ProgressBar = $Control/MarginContainer/VBoxContainer/LevelProgression
@onready var timerLabel: Label = $Control/MarginContainer/VBoxContainer/VBoxContainer/TimeSurvived
@onready var levelLabel: Label = $Control/MarginContainer/VBoxContainer/VBoxContainer/Level
@onready var scoreLabel: Label = $Control/MarginContainer/VBoxContainer/VBoxContainer/Score
@onready var optionButton: TextureButton = $TextureButton

func _ready() -> void:
	pauseMenu = get_tree().get_first_node_in_group("PauseMenu")
	
func UpdateLevelProgression(newProgression: int, newMaxValue: int):
	levelProgression.max_value = newMaxValue
	if levelProgression:
		levelProgression.value = newProgression

func UpdateScore(newScore: int):
	if scoreLabel:
		scoreLabel.text = "Score : " + str(newScore)

func UpdateTimer(newTimer: int):
	if timerLabel:
		timerLabel.text = "Time Survived : " + str(newTimer)
		

func UpdateLevel(newLevel: int):
	if levelLabel:
		levelLabel.text = "Level : " + str(newLevel)


func onOptionButtonPressed() -> void:
	if pauseMenu:
		pauseMenu.open_pause_menu()
