class_name Player
extends CharacterBody3D

# UI
var healthbar: ProgressBar

# Gameplay
var move_inputs: Vector2

#Bonus
var active_bonuses: Array[BonusItem.BonusType] = []
var bonus_speed_mult: float = 1.0
var bonus_damage_mult: float = 1.0
var bonus_attack_speed_mult: float = 1.0

# Stats
var meleeDamage: float
var rangeDamage: float
var areaDamage: float

var maxPv: float 
var currentPv: float = 0 
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
	healthbar = get_tree().get_first_node_in_group("HealthBar")
	
	UpdateStats()
	currentPv = maxPv
	UpdateHealthBar()
	PlayerStatManager.signalStatsUpdated.connect(UpdateStats)
	SetAttackIntervals()
	
	meleeAttackTimer.start()
	meleeAttackTimer.timeout.connect(meleeAttack)

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
	var oldMaxPv = maxPv
	maxPv = PlayerStatManager.currentHealth
	currentPv += maxPv - oldMaxPv
	UpdateHealthBar()
	
	meleeDamage = PlayerStatManager.currentMeleeDammage * bonus_damage_mult
	rangeDamage = PlayerStatManager.currentRangeDammage * bonus_damage_mult
	areaDamage = PlayerStatManager.currentAreaDammage * bonus_damage_mult
	
	meleeAttackInterval = PlayerStatManager.currentMeleeAttackInterval / bonus_attack_speed_mult
	rangeAttackInterval = PlayerStatManager.currentRangeAttackInterval
	
	if areaAttack:
		areaAttackInterval = PlayerStatManager.currentAreaAttackInterval
		
	SetAttackIntervals()
	
	moveSpeed = PlayerStatManager.currentMovementSpeed * bonus_speed_mult
	
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
	rangeAttack.isEnemyATarget = true
	rangeAttack.InitTargetToAttack()

func _physics_process(delta: float) -> void:
	read_move_inputs()
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if move_inputs != Vector2.ZERO:
		var direction = Vector3(move_inputs.x, 0, move_inputs.y).normalized()
		velocity.x = direction.x * moveSpeed
		velocity.z = direction.z * moveSpeed
		
		look_at(global_position + direction, Vector3.UP)
		rotation_degrees.x = 0
		rotation_degrees.z = 0 
	else:
		velocity.x = move_toward(velocity.x, 0, moveSpeed)
		velocity.z = move_toward(velocity.z, 0, moveSpeed)

	move_and_slide()

func read_move_inputs():
	move_inputs.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	move_inputs.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	move_inputs = move_inputs.normalized()


func ApplyBonus(type: BonusItem.BonusType) -> void:
	if active_bonuses.has(type):
		return 

	print("Nouveau Bonus activé : ", type)
	
	match type:
		BonusItem.BonusType.HEAL:
			currentPv = min(currentPv + (maxPv * 0.25), maxPv)
			UpdateHealthBar()

		BonusItem.BonusType.SUPER_SPEED:
			start_stackable_bonus(type, func(): 
				bonus_speed_mult *= 2.0
				UpdateStats()
			, func():
				bonus_speed_mult /= 2.0
				UpdateStats()
			)

		BonusItem.BonusType.SUPER_ATTACK_SPEED:
			start_stackable_bonus(type, func(): 
				bonus_attack_speed_mult *= 2.0
				UpdateStats()
			, func():
				bonus_attack_speed_mult /= 2.0
				UpdateStats()
			)

		BonusItem.BonusType.SUPER_DAMAGE:
			start_stackable_bonus(type, func():
				bonus_damage_mult *= 2.0
				UpdateStats()
			, func():
				bonus_damage_mult /= 2.0
				UpdateStats()
			)

		BonusItem.BonusType.NUKE:
			var enemies = get_tree().get_nodes_in_group("Enemy")
			for enemy in enemies:
				if is_instance_valid(enemy) and enemy.has_method("TakeDammage"):
					if(enemy is BossEnemy):
						enemy.TakeDammage(enemy.currentPv * 0.25)
					else:
						enemy.TakeDammage(99999)

func start_stackable_bonus(type: BonusItem.BonusType, apply_fn: Callable, reset_fn: Callable):
	active_bonuses.append(type)
	apply_fn.call()
	await get_tree().create_timer(8.0).timeout
	reset_fn.call()
	active_bonuses.erase(type)
