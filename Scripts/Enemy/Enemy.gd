class_name Enemy
extends CharacterBody3D

# UI
var healthbar: ProgressBar

# Gameplay
var player: Player

# Stats
var maxPv: float
var currentPv: float
var damage: float
var moveSpeed: float

func UpdateHealthBar() -> void:
	healthbar.max_value = maxPv
	healthbar.update(currentPv)

func TakeDammage(damageTaken: float) -> void:
	if currentPv - damageTaken > 0:
		currentPv -= damageTaken
		healthbar.update(currentPv)
	else:
		queue_free()
	return

# Overide a chaque type d'enemy
func InitStat():
	maxPv = 1.0
	currentPv = maxPv
