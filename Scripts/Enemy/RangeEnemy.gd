class_name RangeEnemy
extends Enemy

# Layers (project: layer_1 = Map, layer_2 = Player, layer_3 = Enemy)
const MAP_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 3
const DEFAULT_LAYER := 1 # fallback if Player is still on default layer

const RANGE_ATTACK_ANIM: StringName = &"Attaque_distance"
const RANGE_ATTACK_ANIM_STOP_AFTER_SEC := 2.5

const WALK_ANIM: StringName = &"Marche_femme"
const DEATH_ANIM: StringName = &"Mort"
const DEATH_VISIBILITY_SEC := 2.5

# Attack Timer
var rangeAttackInterval: float
@onready var rangeAttackTimer:Timer = $Timers/RangeAttackTimer

@onready var _anim_player: AnimationPlayer = $AnimationPlayer
var _range_attack_anim_token: int = 0
var _death_token: int = 0
var _is_dead: bool = false

var projectilSpeed: float
var isCloseEnoughToPlayer: bool = false

# Attack Scenes
@export var rangeAttackScene: PackedScene = preload("res://Scenes/Attack/RangeAttack.tscn")

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Player
	if player == null and Engine.has_singleton("GameManager") and GameManager.player:
		player = GameManager.player
	if player == null:
		push_warning("RangeEnemy: Player introuvable (group 'Player' manquant ?)")

	# Ensure collisions are consistent after model swap
	collision_layer = _layer_bit(ENEMY_LAYER)
	collision_mask = _layer_bit(MAP_LAYER) | _layer_bit(PLAYER_LAYER) | _layer_bit(DEFAULT_LAYER) | _layer_bit(ENEMY_LAYER)

	healthbar = $HealthBarSprite/SubViewport/CanvasLayer/HealthBar
	InitStat()
	_ensure_walk_animation_loops()
	
	var random_offset = randf_range(0.0, 1.0)
	await get_tree().create_timer(random_offset).timeout
	rangeAttackTimer.wait_time = rangeAttackInterval
	if !rangeAttackTimer.timeout.is_connected(Attack):
		rangeAttackTimer.timeout.connect(Attack)
	rangeAttackTimer.start()

func _ensure_walk_animation_loops() -> void:
	if _is_dead:
		return
	if _anim_player == null:
		return
	if not _anim_player.has_animation(WALK_ANIM):
		return
	var anim: Animation = _anim_player.get_animation(WALK_ANIM)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR

func _update_walk_animation(is_moving: bool) -> void:
	if _is_dead:
		return
	if _anim_player == null:
		return
	if not _anim_player.has_animation(WALK_ANIM):
		return

	if is_moving:
		# As soon as we start moving, immediately cancel the ranged attack animation.
		if _anim_player.is_playing() and _anim_player.current_animation == String(RANGE_ATTACK_ANIM):
			_anim_player.stop()
			_anim_player.play(WALK_ANIM)
			return

		if _anim_player.current_animation != String(WALK_ANIM) or not _anim_player.is_playing():
			_anim_player.play(WALK_ANIM)
	else:
		if _anim_player.current_animation == String(WALK_ANIM) and _anim_player.is_playing():
			_anim_player.stop()


func Attack()->void:
	if _is_dead:
		return
	if !isCloseEnoughToPlayer:
		return
	_play_range_attack_animation()
	if rangeAttackScene == null:
		push_error("RangeEnemy.Attack: rangeAttackScene est null (PackedScene). Assigne la scène du projectile dans l'inspecteur.")
		return
	var rangeAttack = rangeAttackScene.instantiate()
	get_parent().add_child(rangeAttack)
	rangeAttack.global_position = global_position
	rangeAttack.global_rotation = global_rotation
	rangeAttack.speed = projectilSpeed
	rangeAttack.damage = damage
	rangeAttack.isEnemyATarget = false
	rangeAttack.InitTargetToAttack()

func _play_range_attack_animation() -> void:
	if _is_dead:
		return
	if _anim_player == null:
		return
	if not _anim_player.has_animation(RANGE_ATTACK_ANIM):
		return

	_range_attack_anim_token += 1
	var token := _range_attack_anim_token

	_anim_player.play(RANGE_ATTACK_ANIM)
	get_tree().create_timer(RANGE_ATTACK_ANIM_STOP_AFTER_SEC).timeout.connect(func() -> void:
		if token != _range_attack_anim_token:
			return
		if _anim_player == null:
			return
		if _anim_player.current_animation == String(RANGE_ATTACK_ANIM) and _anim_player.is_playing():
			_anim_player.stop()
	)


func InitStat():
	maxPv = GameDifficulty.rangeCurrentHealth
	currentPv = maxPv
	moveSpeed = GameDifficulty.rangeCurrentMovementSpeed
	damage = GameDifficulty.rangeCurrentDammage
	rangeAttackInterval = GameDifficulty.rangeCurrentAttackTiming
	projectilSpeed = GameDifficulty.rangeCurrentProjectilSpeed
	UpdateHealthBar()

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		var target_position = player.global_position
		target_position.y = global_position.y
		look_at(target_position, Vector3.UP)
		rotate_y(deg_to_rad(180))

		if distance > 10.0:
			isCloseEnoughToPlayer = false
			var direction: Vector3 = (player.global_position - global_position).normalized()
			velocity.x = direction.x * moveSpeed
			velocity.z = direction.z * moveSpeed
			_update_walk_animation(true)
		else:
			isCloseEnoughToPlayer = true
			velocity.x = 0
			velocity.z = 0
			_update_walk_animation(false)

		if !is_on_floor():
			velocity.y = get_gravity().y
	else:
		# Re-try player acquisition if it wasn't ready at spawn time
		player = get_tree().get_first_node_in_group("Player") as Player
		if player == null and Engine.has_singleton("GameManager") and GameManager.player:
			player = GameManager.player
		velocity = Vector3.ZERO
		_update_walk_animation(false)

	move_and_slide()

func TakeDammage(damageTaken: float) -> void:
	if _is_dead:
		return

	if currentPv - damageTaken > 0:
		currentPv -= damageTaken
		if healthbar:
			healthbar.update(currentPv)
		return

	currentPv = 0
	if healthbar:
		healthbar.update(currentPv)
	_die()

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	_death_token += 1
	var token := _death_token

	# Cancel any pending animation stop callbacks from ranged attacks.
	_range_attack_anim_token += 1

	# Stop attacks.
	if rangeAttackTimer:
		rangeAttackTimer.stop()

	# Disable collisions so it doesn't keep interacting while dead.
	collision_layer = 0
	collision_mask = 0

	# Stop all animations and play death.
	if _anim_player != null and _anim_player.has_animation(DEATH_ANIM):
		_anim_player.stop()
		var anim: Animation = _anim_player.get_animation(DEATH_ANIM)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE
		_anim_player.play(DEATH_ANIM)

	# Keep visibility for a short time, then remove.
	get_tree().create_timer(DEATH_VISIBILITY_SEC).timeout.connect(func() -> void:
		if token != _death_token:
			return
		queue_free()
	)

func _layer_bit(layer_number: int) -> int:
	return 1 << (layer_number - 1)
