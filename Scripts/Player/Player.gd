class_name Player
extends CharacterBody3D

# Gameplay
var move_inputs: Vector2
var currentLevel = 1
var dammage = 1

# Health
@export var maxPv: int = 50
@export var currentPv: int = maxPv

# Movement 
@export var moveSpeed: float = 5.0

func _physics_process(delta: float) -> void:
	read_move_inputs()
	move_inputs *= moveSpeed * delta

	if move_inputs != Vector2.ZERO:
		var direction = Vector3(move_inputs.x, 0.0, move_inputs.y)
		global_position += direction
		
	rotation_degrees.x = 0
	rotation_degrees.z = 0


func read_move_inputs():
	move_inputs.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	move_inputs.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	move_inputs = move_inputs.normalized()
	return
