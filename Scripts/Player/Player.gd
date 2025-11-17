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

# Attack Timer
@export var meleeAttackInterval: float = 1.5
@onready var meleeAttackTimer:Timer = $Timers/MeleAttackTimer

@export var rangeAttackInterval: float = 0.75
@onready var rangeAttackTimer:Timer = $Timers/RangeAttackTimer

# Attack Scenes
@export var meleeAttackScene: PackedScene
@export var rangeAttackScene: PackedScene
@export var zoneAttackScene: PackedScene

func _ready() -> void:
	meleeAttackTimer.start(meleeAttackInterval)
	meleeAttackTimer.timeout.connect(meleeAttack)

func TakeDammage(dammage: int) -> void:
	if currentPv - dammage > 0:
		currentPv -= dammage
	else:
		currentPv = 0
	print("player : " + str(currentPv))
	return

func meleeAttack() -> void:
	var meleeAttack = meleeAttackScene.instantiate()
	var attack_distance: float = 1.17
	var local_offset: Vector3 = Vector3(0, 0, -attack_distance)
	meleeAttack.position = local_offset
	meleeAttack.rotation = Vector3.ZERO
	add_child(meleeAttack)
	
func _physics_process(delta: float) -> void:
	read_move_inputs()
	move_inputs *= moveSpeed * delta
	
	if move_inputs != Vector2.ZERO:
		global_position += Vector3(move_inputs.x, 0.0, move_inputs.y)
		var look_direction = Vector3(move_inputs.x, 0, move_inputs.y).normalized()
		look_at(global_position + look_direction, Vector3.UP)
		
	rotation_degrees.x = 0
	rotation_degrees.z = 0 

func read_move_inputs():
	move_inputs.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	move_inputs.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	move_inputs = move_inputs.normalized()
	return
