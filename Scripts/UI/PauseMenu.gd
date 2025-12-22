class_name PauseMenu
extends CanvasLayer

@onready var resumeButton: Button = $Control/MarginContainer/VBoxContainer/TopButton

@onready var meleeDamagePG: ProgressBar = $Control/PanelContainer/VBoxContainer/MeleeDamage/ProgressBar
@onready var RangeDamagePG: ProgressBar = $Control/PanelContainer/VBoxContainer/RangeDamage/ProgressBar
@onready var AreaDamagePG: ProgressBar = $Control/PanelContainer/VBoxContainer/AreaDamage/ProgressBar
@onready var MovementSpeedPG: ProgressBar = $Control/PanelContainer/VBoxContainer/MovementSpeed/ProgressBar


func _ready() -> void:
	if meleeDamagePG:
		meleeDamagePG.max_value = PlayerStatManager.maxMeleeDammage
	if AreaDamagePG:
		AreaDamagePG.max_value = PlayerStatManager.maxAreaDammage
	if RangeDamagePG:
		RangeDamagePG.max_value = PlayerStatManager.maxRangeDammage
	if MovementSpeedPG:
		MovementSpeedPG.max_value = PlayerStatManager.maxMovementSpeed
	UpdateProgressBars()
	hide()

func open_pause_menu() -> void:
	if GameManager.gameOver:
		resumeButton.visible = false
	show()
	get_tree().paused = true
	
func onResumeButtonPressed() -> void:
	hide()
	get_tree().paused = false

func onRestartButtonPressed() -> void:
	get_tree().paused = false
	GameManager.resetData()
	GameDifficulty.resetData()
	PlayerStatManager.resetData()
	get_tree().reload_current_scene()

func onMenuButtonPressed() -> void:
	get_tree().paused = false
	GameManager.resetData()
	GameDifficulty.resetData()
	PlayerStatManager.resetData()
	get_tree().change_scene_to_file("res://Scenes/UI/startMenu.tscn")

func UpdateProgressBars():
	if meleeDamagePG:
		meleeDamagePG.value = PlayerStatManager.currentMeleeDammage
	if AreaDamagePG:
		AreaDamagePG.value = PlayerStatManager.currentAreaDammage
	if RangeDamagePG:
		RangeDamagePG.value = PlayerStatManager.currentRangeDammage
	if MovementSpeedPG:
		MovementSpeedPG.value = PlayerStatManager.currentMovementSpeed
	
