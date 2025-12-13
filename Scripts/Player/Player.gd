class_name Player
extends CharacterBody3D

# UI
var healthbar: ProgressBar

# Gameplay
var move_inputs: Vector2

# Stats
var meleeDamage: float
var rangeDamage: float
var areaDamage: float

var maxPv: float 
var currentPv: float 
var moveSpeed: float

# Attack Timer
var meleeAttackInterval: float
@onready var meleeAttackTimer:Timer = $Timers/MeleAttackTimer

var rangeAttackInterval: float
@onready var rangeAttackTimer:Timer = $Timers/RangeAttackTimer

var areaAttackInterval: float
var areaAttack: Node3D

# Attack Scenes
@export var meleeAttackScene: PackedScene
@export var rangeAttackScene: PackedScene
@export var areaAttackScene: PackedScene

func _ready() -> void:
	InitStats()
	SetAttackIntervals()
	meleeAttackTimer.start()
	meleeAttackTimer.timeout.connect(meleeAttack)
	
	rangeAttackTimer.start()
	rangeAttackTimer.timeout.connect(rangeAttack)
	
	AreaAttack()
	
	healthbar = get_tree().get_first_node_in_group("HealthBar")
	healthbar.max_value = maxPv
	healthbar.update(currentPv)
	
func InitStats():
	maxPv = PlayerStatManager.currentHealth
	currentPv = maxPv
	
	meleeDamage = PlayerStatManager.currentMeleeDammage
	rangeDamage = PlayerStatManager.currentRangeDammage
	areaDamage = PlayerStatManager.currentAreaDammage
	
	meleeAttackInterval = PlayerStatManager.currentMeleeAttackInterval
	rangeAttackInterval = PlayerStatManager.currentRangeAttackInterval
	if areaAttack:
		areaAttackInterval = PlayerStatManager.currentAreaAttackInterval
	
	moveSpeed = PlayerStatManager.currentMovementSpeed

func SetAttackIntervals():
	meleeAttackTimer.wait_time = meleeAttackInterval
	rangeAttackTimer.wait_time = rangeAttackInterval
	if areaAttack:
		areaAttack.attackInterval = areaAttackInterval
		areaAttack.attackTimer.wait_time = areaAttack

func TakeDammage(dammage: int) -> void:
	if currentPv - dammage > 0:
		currentPv -= dammage
		healthbar.update(currentPv)
	else:
		currentPv = 0
		healthbar.update(currentPv)
	return

func meleeAttack() -> void:
	var meleeAttack = meleeAttackScene.instantiate()
	var attack_distance: float = 1.17
	var local_offset: Vector3 = Vector3(0, 0, -attack_distance)
	meleeAttack.position = local_offset
	meleeAttack.rotation = Vector3.ZERO
	meleeAttack.damage = meleeDamage
	add_child(meleeAttack)

func rangeAttack() -> void:
	var rangeAttack = rangeAttackScene.instantiate()
	get_parent().add_child(rangeAttack)
	rangeAttack.global_position = global_position
	rangeAttack.global_rotation = global_rotation
	rangeAttack.damage = rangeDamage
	rangeAttack.InitTargetToAttack()

func AreaAttack() -> void:
	areaAttack = areaAttackScene.instantiate()
	areaAttack.damage = areaDamage
	add_child(areaAttack)

func _physics_process(delta: float) -> void:
	read_move_inputs()
	move_inputs *= moveSpeed * delta
	
	if !is_on_floor():
		velocity.y = get_gravity().y
	
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
