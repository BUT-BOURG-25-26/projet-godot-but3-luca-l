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

#Animation 
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const MELEE_ANIM_NAME := "Attaque_melee"
var melee_anim_length := 0.0
var is_melee_attacking := false
var melee_anim_available := false

func _ready() -> void:
	healthbar = get_tree().get_first_node_in_group("HealthBar")
	
	UpdateStats()
	PlayerStatManager.signalStatsUpdated.connect(UpdateStats)
	SetAttackIntervals()
	
	meleeAttackTimer.start()
	meleeAttackTimer.timeout.connect(meleeAttack)
	anim_player.animation_finished.connect(_on_animation_finished)
	if anim_player.has_animation(MELEE_ANIM_NAME):
		melee_anim_length = anim_player.get_animation(MELEE_ANIM_NAME).length
		melee_anim_available = true
	else:
		push_warning("Animation '%s' introuvable dans AnimationPlayer" % MELEE_ANIM_NAME)
	
func _get_melee_anim_speed() -> float:
	if melee_anim_length <= 0.0:
		return 1.0

	var interval: float = maxf(meleeAttackInterval, 0.01)
	return clampf(melee_anim_length / interval, 0.5, 3.0)

func ActivateRangeAttack():
	rangeAttackTimer.start()
	rangeAttackTimer.timeout.connect(rangeAttack)

func ActivateAreaAttack() -> void:
	if areaAttack:
		return 
	areaAttack = areaAttackScene.instantiate()
	areaAttack.damage = areaDamage
	add_child(areaAttack)
	SetAttackIntervals()

func UpdateHealthBar():
	healthbar.max_value = maxPv
	healthbar.update(currentPv)

func UpdateStats():
	maxPv = PlayerStatManager.currentHealth
	currentPv = maxPv
	UpdateHealthBar()
	
	meleeDamage = PlayerStatManager.currentMeleeDammage
	rangeDamage = PlayerStatManager.currentRangeDammage
	areaDamage = PlayerStatManager.currentAreaDammage
	
	meleeAttackInterval = PlayerStatManager.currentMeleeAttackInterval
	rangeAttackInterval = PlayerStatManager.currentRangeAttackInterval
	if areaAttack:
		areaAttackInterval = PlayerStatManager.currentAreaAttackInterval
	SetAttackIntervals()
	
	moveSpeed = PlayerStatManager.currentMovementSpeed
	print(
	"[Player]",
	"| Melee:", meleeDamage,
	"| Range:", rangeDamage,
	"| Area:", areaDamage,
	"| Health:", currentPv,
	"| MoveSpeed:", moveSpeed,
	"| RangeInterval:", rangeAttackInterval,
	"| MeleeInterval:", meleeAttackInterval,
	"| AreaInterval:", areaAttackInterval
	)

func SetAttackIntervals():
	meleeAttackTimer.wait_time = meleeAttackInterval
	rangeAttackTimer.wait_time = rangeAttackInterval 

	if areaAttack:
		areaAttack.attackInterval = areaAttackInterval
		areaAttack.attackTimer.wait_time = areaAttackInterval

func TakeDammage(dammage: int) -> void:
	if currentPv - dammage > 0:
		currentPv -= dammage
		healthbar.update(currentPv)
	else:
		currentPv = 0
		healthbar.update(currentPv)
	return

func meleeAttack() -> void:
	if is_melee_attacking:
		return
	is_melee_attacking = true

	var melee_anim_played := false
	if melee_anim_available:
		var speed := _get_melee_anim_speed()
		anim_player.play(MELEE_ANIM_NAME, speed)
		anim_player.seek(0.0, true)
		melee_anim_played = true

	# Spawn attaque
	var meleeAttack = meleeAttackScene.instantiate()
	var attack_distance: float = 1.17
	meleeAttack.position = Vector3(0, 0, -attack_distance)
	meleeAttack.rotation = Vector3.ZERO
	meleeAttack.damage = meleeDamage
	add_child(meleeAttack)

	if !melee_anim_played:
		_reset_melee_attack_state()


func rangeAttack() -> void:
	var rangeAttack = rangeAttackScene.instantiate()
	get_parent().add_child(rangeAttack)
	rangeAttack.global_position = global_position
	rangeAttack.global_rotation = global_rotation
	rangeAttack.damage = rangeDamage
	rangeAttack.isEnemyATarget = true
	rangeAttack.InitTargetToAttack()

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

func _reset_melee_attack_state() -> void:
	is_melee_attacking = false

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == MELEE_ANIM_NAME:
		_reset_melee_attack_state()
