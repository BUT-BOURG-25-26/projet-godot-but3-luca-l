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

# Bonus
@export var bonus_item_scene: PackedScene
@export var drop_chance: float = 1.0/5.0

func UpdateHealthBar() -> void:
	healthbar.max_value = maxPv
	healthbar.update(currentPv)

func TakeDammage(damageTaken: float) -> void:
	if currentPv - damageTaken > 0:
		currentPv -= damageTaken
		healthbar.update(currentPv)
	else:
		if randf() < drop_chance:
			spawn_bonus()
		queue_free()
	return

# Overide a chaque type d'enemy
func InitStat():
	maxPv = 1.0
	currentPv = maxPv

func spawn_bonus():
	if bonus_item_scene:
		var bonus = bonus_item_scene.instantiate()
		get_tree().current_scene.add_child(bonus)
		bonus.global_position = global_position
		bonus.global_position.y = 0.5
