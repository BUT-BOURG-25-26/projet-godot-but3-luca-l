class_name MenuLevelUp
extends CanvasLayer

@onready var LeftButton: Button = $Control/MarginContainer/HBoxContainer/LeftButton
@onready var middleButton: Button = $Control/MarginContainer/HBoxContainer/MiddleButton
@onready var rightButton: Button = $Control/MarginContainer/HBoxContainer/RightButton

var availableUpgrades: Array[Dictionary]

func _ready() -> void:
	LeftButton.pressed.connect(selectUpgrade.bind(0))
	middleButton.pressed.connect(selectUpgrade.bind(1))
	rightButton.pressed.connect(selectUpgrade.bind(2))
	
	visible = false 
	
func showLevelUpMenu() -> void:
	availableUpgrades = PlayerStatManager.GetRandomUpgrades(3)
	
	if availableUpgrades.is_empty():
		get_tree().paused = false
		visible = false
		GameManager.ContinueToNexLevel()
		return
	
	DisplayAvailableButton(availableUpgrades)
	
	get_tree().paused = true
	visible = true

func DisplayAvailableButton(availableUpgrades: Array[Dictionary]):
	if availableUpgrades.size() == 3:
		LeftButton.text = availableUpgrades[0].name
		middleButton.text = availableUpgrades[1].name
		rightButton.text = availableUpgrades[2].name
	elif availableUpgrades.size() == 2:
		LeftButton.text = availableUpgrades[0].name
		middleButton.text = availableUpgrades[1].name
		rightButton.disabled = true
	elif availableUpgrades.size() == 1:
		middleButton.text = availableUpgrades[1].name
		LeftButton.disabled = true
		rightButton.disabled = true

func selectUpgrade(index: int) -> void:
	var selectedUpgrade = availableUpgrades[index]
	PlayerStatManager.ApplyUpgrade(selectedUpgrade)
	get_tree().paused = false
	visible = false
	GameManager.StartNextLevel()
