class_name Player
extends CharacterBody3D

const MIN_TIMER_WAIT_SEC: float = 0.01

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
@export var rangeAttackScene: PackedScene = preload("res://Scenes/Attack/RangedAttackPlayer.tscn")
@export var areaAttackScene: PackedScene

@export var range_attack_spawn_height: float = 1.1
@export var range_attack_spawn_forward: float = 0.35

#Animation 
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var animation_controller: PlayerAnimationController
const PUSH_UP_ACTION := "PushUp"

const PLAYER_RANGE_ATTACK_PATH := "res://Scenes/Attack/RangedAttackPlayer.tscn"

func _ready() -> void:
	healthbar = get_tree().get_first_node_in_group("HealthBar")
	if rangeAttackScene == null or rangeAttackScene.resource_path != PLAYER_RANGE_ATTACK_PATH:
		rangeAttackScene = preload(PLAYER_RANGE_ATTACK_PATH)
	animation_controller = PlayerAnimationController.new()
	add_child(animation_controller)
	animation_controller.setup(anim_player)
	
	UpdateStats()
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
	# `UnlockAreaAttack()` can call this before `signalStatsUpdated` runs, so
	# our local `areaAttackInterval` may still be 0 here.
	areaAttackInterval = maxf(MIN_TIMER_WAIT_SEC, PlayerStatManager.currentAreaAttackInterval)
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
	if animation_controller:
		animation_controller.update_melee_interval(meleeAttackInterval)
	
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
	meleeAttackTimer.wait_time = maxf(MIN_TIMER_WAIT_SEC, meleeAttackInterval)
	rangeAttackTimer.wait_time = maxf(MIN_TIMER_WAIT_SEC, rangeAttackInterval)

	if areaAttack:
		var safe_area_interval: float = maxf(MIN_TIMER_WAIT_SEC, areaAttackInterval)
		areaAttack.attackInterval = safe_area_interval
		areaAttack.attackTimer.wait_time = safe_area_interval

func TakeDammage(dammage: int) -> void:
	if currentPv - dammage > 0:
		currentPv -= dammage
		healthbar.update(currentPv)
	else:
		currentPv = 0
		healthbar.update(currentPv)
	return

func meleeAttack() -> void:
	if animation_controller and (animation_controller.is_melee_attack_active() or animation_controller.is_pushup_active()):
		return

	var melee_anim_played := animation_controller and animation_controller.try_play_melee_attack(meleeAttackInterval)

	# Spawn attaque
	var meleeAttack = meleeAttackScene.instantiate()
	var attack_distance: float = 1.4
	# Godot considère -Z comme l'avant.
	var forward := (-global_transform.basis.z).normalized()
	if forward == Vector3.ZERO:
		forward = Vector3.FORWARD
	add_child(meleeAttack)
	# Place l'attaque devant le player (dans son repère local) + un léger offset Y
	# pour éviter que le volume traverse le corps.
	meleeAttack.position = Vector3(0.0, 0, attack_distance + 3.0)
	if meleeAttack.has_method("set_attack_direction"):
		meleeAttack.call("set_attack_direction", -forward)
	meleeAttack.damage = meleeDamage

	if animation_controller and !melee_anim_played:
		animation_controller.reset_melee_attack_state()


func rangeAttack() -> void:
	var rangeAttack = rangeAttackScene.instantiate()
	get_parent().add_child(rangeAttack)
	var forward := (-global_transform.basis.z).normalized()
	if forward == Vector3.ZERO:
		forward = Vector3.FORWARD
	var spawn_position := global_position + Vector3.UP * range_attack_spawn_height + forward * range_attack_spawn_forward
	rangeAttack.global_position = spawn_position
	rangeAttack.global_rotation = global_rotation
	rangeAttack.damage = rangeDamage
	rangeAttack.isEnemyATarget = true
	rangeAttack.InitTargetToAttack()

func _physics_process(delta: float) -> void:
	if animation_controller and Input.is_action_just_pressed(PUSH_UP_ACTION):
		animation_controller.trigger_pushup_sequence()
	read_move_inputs()
	var pushup_active := animation_controller and animation_controller.is_pushup_active()
	if pushup_active:
		move_inputs = Vector2.ZERO
	else:
		move_inputs *= moveSpeed * delta
	var is_moving := move_inputs != Vector2.ZERO
	
	if !is_on_floor():
		velocity.y = get_gravity().y
	
	if is_moving:
		global_position += Vector3(move_inputs.x, 0.0, move_inputs.y)
		var look_direction = Vector3(move_inputs.x, 0, move_inputs.y).normalized()
		# Godot considère -Z comme l'avant, donc on inverse pour garder le modèle aligné avec le déplacement
		look_at(global_position - look_direction, Vector3.UP)
		
	rotation_degrees.x = 0
	rotation_degrees.z = 0 

	if animation_controller:
		animation_controller.update_movement_animation(is_moving, moveSpeed)

func read_move_inputs():
	move_inputs.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	move_inputs.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	move_inputs = move_inputs.normalized()
	return
