class_name Player
extends CharacterBody3D

const MIN_TIMER_WAIT_SEC: float = 0.01

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
@export var rangeAttackScene: PackedScene = preload("res://Scenes/Attack/RangedAttackPlayer.tscn")
@export var areaAttackScene: PackedScene

@export var range_attack_spawn_height: float = 1.1
@export var range_attack_spawn_forward: float = 0.35

#Animation 
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var animation_controller: PlayerAnimationController
const PUSH_UP_ACTION := "PushUp"

const DEATH_ANIM: StringName = &"Mort"
const DEATH_MENU_FALLBACK_SEC: float = 1.5
var _death_sequence_started: bool = false

const NUKE_EMOTE_ANIM: StringName = &"Fortnite_dance"
const NUKE_EMOTE_SPEED: float = 1.5
var _nuke_emote_active: bool = false

const PLAYER_RANGE_ATTACK_PATH := "res://Scenes/Attack/RangedAttackPlayer.tscn"

func _ready() -> void:
	healthbar = get_tree().get_first_node_in_group("HealthBar")
	if rangeAttackScene == null or rangeAttackScene.resource_path != PLAYER_RANGE_ATTACK_PATH:
		rangeAttackScene = preload(PLAYER_RANGE_ATTACK_PATH)
	animation_controller = PlayerAnimationController.new()
	add_child(animation_controller)
	animation_controller.setup(anim_player)
	if anim_player and !anim_player.animation_finished.is_connected(_on_player_animation_finished):
		anim_player.animation_finished.connect(_on_player_animation_finished)
	
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
	meleeAttackTimer.wait_time = maxf(MIN_TIMER_WAIT_SEC, meleeAttackInterval)
	rangeAttackTimer.wait_time = maxf(MIN_TIMER_WAIT_SEC, rangeAttackInterval)

	if areaAttack:
		var safe_area_interval: float = maxf(MIN_TIMER_WAIT_SEC, areaAttackInterval)
		areaAttack.attackInterval = safe_area_interval
		areaAttack.attackTimer.wait_time = safe_area_interval

func TakeDammage(dammage: int) -> void:
	if _nuke_emote_active:
		return
	if _death_sequence_started:
		return
	if currentPv - dammage > 0:
		currentPv -= dammage
		healthbar.update(currentPv)
	else:
		currentPv = 0
		healthbar.update(currentPv)
		_start_death_sequence()
	return


func _start_death_sequence() -> void:
	if _death_sequence_started:
		return
	_death_sequence_started = true

	# Stop any gameplay actions immediately.
	if is_instance_valid(meleeAttackTimer):
		meleeAttackTimer.stop()
	if is_instance_valid(rangeAttackTimer):
		rangeAttackTimer.stop()
	if is_instance_valid(areaAttack) and ("attackTimer" in areaAttack) and is_instance_valid(areaAttack.attackTimer):
		areaAttack.attackTimer.stop()

	velocity = Vector3.ZERO

	# Prevent other animations from overriding the death animation.
	if animation_controller:
		animation_controller.set_animation_lock(true)

	var wait_sec := DEATH_MENU_FALLBACK_SEC
	if anim_player != null and anim_player.has_animation(DEATH_ANIM):
		anim_player.speed_scale = 1.0
		var anim: Animation = anim_player.get_animation(DEATH_ANIM)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE
			wait_sec = maxf(0.1, anim.length)
		anim_player.stop()
		anim_player.play(DEATH_ANIM)
		anim_player.seek(0.0, true)

	# Only show the Game Over menu after the death animation.
	get_tree().create_timer(wait_sec).timeout.connect(func() -> void:
		GameManager.gameOver = true
	)

func meleeAttack() -> void:
	if _nuke_emote_active:
		return
	if _death_sequence_started:
		return
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
	if _death_sequence_started:
		return
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
	if _death_sequence_started:
		# Keep gravity but prevent player-driven actions.
		move_inputs = Vector2.ZERO
		if !is_on_floor():
			velocity.y = get_gravity().y
		velocity.x = move_toward(velocity.x, 0, moveSpeed)
		velocity.z = move_toward(velocity.z, 0, moveSpeed)
		move_and_slide()
		return
	if _nuke_emote_active:
		move_inputs = Vector2.ZERO
		# Keep gravity, but prevent player-driven movement.
		if !is_on_floor():
			velocity.y = get_gravity().y
		velocity.x = move_toward(velocity.x, 0, moveSpeed)
		velocity.z = move_toward(velocity.z, 0, moveSpeed)
		move_and_slide()
		return

	if animation_controller and Input.is_action_just_pressed(PUSH_UP_ACTION):
		animation_controller.trigger_pushup_sequence()
	read_move_inputs()
	var pushup_active := animation_controller and animation_controller.is_pushup_active()
	if pushup_active:
		move_inputs = Vector2.ZERO
	else:
		move_inputs *= moveSpeed * delta
	if !is_on_floor():
		velocity.y = get_gravity().y
	
	var is_moving := move_inputs != Vector2.ZERO
	if is_moving:
		var direction = Vector3(move_inputs.x, 0, move_inputs.y).normalized()
		velocity.x = direction.x * moveSpeed
		velocity.z = direction.z * moveSpeed
		
		look_at(global_position + direction, Vector3.UP)
		rotate_y(deg_to_rad(180))
		rotation_degrees.x = 0
		rotation_degrees.z = 0 
	else:
		velocity.x = move_toward(velocity.x, 0, moveSpeed)
		velocity.z = move_toward(velocity.z, 0, moveSpeed)
	move_and_slide()

	if animation_controller:
		animation_controller.update_movement_animation(is_moving, moveSpeed)

func _start_nuke_emote() -> void:
	if anim_player == null or !anim_player.has_animation(NUKE_EMOTE_ANIM):
		return
	_set_nuke_emote_active(true)
	if animation_controller:
		animation_controller.set_animation_lock(true)
	anim_player.play(NUKE_EMOTE_ANIM, -1.0, NUKE_EMOTE_SPEED)
	anim_player.seek(0.0, true)

func _set_nuke_emote_active(active: bool) -> void:
	_nuke_emote_active = active
	# Keep player visible; only movement/animations/damage are affected.

func _on_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != NUKE_EMOTE_ANIM:
		return
	if !_nuke_emote_active:
		return
	_set_nuke_emote_active(false)
	if animation_controller:
		animation_controller.set_animation_lock(false)

func read_move_inputs():
	move_inputs.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	move_inputs.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	move_inputs = move_inputs.normalized()


func ApplyBonus(type: BonusItem.BonusType) -> void:
	if active_bonuses.has(type):
		return 

	print("Nouveau Bonus activÃ© : ", type)
	
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
			_start_nuke_emote()

func start_stackable_bonus(type: BonusItem.BonusType, apply_fn: Callable, reset_fn: Callable):
	active_bonuses.append(type)
	apply_fn.call()
	await get_tree().create_timer(8.0).timeout
	reset_fn.call()
	active_bonuses.erase(type)
