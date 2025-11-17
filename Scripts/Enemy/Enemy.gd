class_name Enemy
extends CharacterBody3D

# Gameplay
var player: Player
var currentLevel = 1
@export var dammage = 1

# Health
@export var maxPv: int = 10
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

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Player
