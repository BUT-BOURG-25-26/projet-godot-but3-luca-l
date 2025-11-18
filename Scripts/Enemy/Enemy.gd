class_name Enemy
extends CharacterBody3D

# Gameplay
var player: Player
var currentLevel = 1
@export var dammage = 1

# Health
@export var maxPv: int = 1
@export var currentPv: int = maxPv

# Movement 
@export var moveSpeed: float = 3.0

func TakeDammage(dammage: int) -> void:
	if currentPv - dammage > 0:
		currentPv -= dammage
	else:
		queue_free()
	print("Enemy : " + str(currentPv))
	return
