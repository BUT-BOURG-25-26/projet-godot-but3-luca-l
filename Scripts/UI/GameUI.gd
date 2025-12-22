class_name GameUI
extends CanvasLayer

var pauseMenu: PauseMenu
@onready var levelProgression: ProgressBar = $Control/MarginContainer/VBoxContainer/LevelProgression
@onready var timerLabel: Label = $Control/MarginContainer/VBoxContainer/VBoxContainer/TimeSurvived
@onready var levelLabel: Label = $Control/MarginContainer/VBoxContainer/VBoxContainer/Level
@onready var scoreLabel: Label = $Control/MarginContainer/VBoxContainer/VBoxContainer/Score
@onready var optionButton: TextureButton = $TextureButton

@onready var meleeIcon: TextureRect = $Control/MarginContainer/VBoxContainer/HBoxContainer/MeleeIcon
@onready var rangeIcon: TextureRect = $Control/MarginContainer/VBoxContainer/HBoxContainer/RangeIcon
@onready var AreaIcon: TextureRect = $Control/MarginContainer/VBoxContainer/HBoxContainer/AreaIcon

func _ready() -> void:
	pauseMenu = get_tree().get_first_node_in_group("PauseMenu")
	rangeIcon.visible = false
	AreaIcon.visible = false
	
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
	
func DisplayRangeIcon():
	if rangeIcon.visible == false:
		rangeIcon.visible = true
	
func DisplayAreeIcon():
	if AreaIcon.visible == false:
		AreaIcon.visible = true
