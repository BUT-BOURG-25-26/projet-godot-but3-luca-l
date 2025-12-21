class_name BossEnemy
extends Enemy

# Layers (project: layer_1 = Map, layer_2 = Player, layer_3 = Enemy)
const MAP_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 3
const DEFAULT_LAYER := 1 # fallback if Player is still on default layer

const DASH_DISTANCE_MIN: float = 2
const MELEE_RANGE: float = 1.5
const DASH_SPEED: float = 20.0
const DASH_ATTACK_DURATION_SEC: float = 0.75

const WALK_ANIM: StringName = &"Marche"
const MELEE_ATTACK_ANIM: StringName = &"Spartan_kick"
const DASH_ANIM_PRIMARY: StringName = &"Attaque_zone"
const DASH_ANIM_FALLBACK: StringName = &"Attaque_zone" # actual name in BossEnemy.tscn
const DEATH_ANIM: StringName = &"Mort"
const DEATH_FALLBACK_SEC: float = 2.5

enum State { CHASE, MELEE, DASH_PREPARE, DASH_ATTACK, STUNNED }
var current_state: State = State.CHASE

# Attack Timer
var dashAttackInterval: float
@onready var dashAttackTimer:Timer = $Timers/DashAttackTimer

var meleeAttackInterval: float
@onready var meleeAttackTimer:Timer = $Timers/MeleeAttackTimer

var chaseDurationTimer: Timer = Timer.new()
const MAX_CHASE_TIME: float = 2

# Stats
var meleeDamage: float
var dashDamage: float
var dash_direction: Vector3 = Vector3.ZERO

var _is_dead: bool = false
var _death_token: int = 0

@onready var _dynamic_hitbox: Area3D = $Armature/Skeleton3D/BoneAttachment3D/DynamicHitbox
@onready var _anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Player
	# Ensure collisions are consistent
	collision_layer = _layer_bit(ENEMY_LAYER)
	collision_mask = _layer_bit(MAP_LAYER) | _layer_bit(PLAYER_LAYER) | _layer_bit(DEFAULT_LAYER) | _layer_bit(ENEMY_LAYER)
	if is_instance_valid(_dynamic_hitbox):
		_dynamic_hitbox.collision_layer = _layer_bit(ENEMY_LAYER)
		_dynamic_hitbox.collision_mask = _layer_bit(MAP_LAYER) | _layer_bit(PLAYER_LAYER) | _layer_bit(DEFAULT_LAYER) | _layer_bit(ENEMY_LAYER)

	healthbar = $HealthBarSprite/SubViewport/CanvasLayer/HealthBar
	InitStat()
	
	chaseDurationTimer.wait_time = MAX_CHASE_TIME
	chaseDurationTimer.one_shot = true
	chaseDurationTimer.timeout.connect(force_dash_if_chasing)
	add_child(chaseDurationTimer)
	
	var random_offset = randf_range(0.0, 1.0)
	await get_tree().create_timer(random_offset).timeout
	
	meleeAttackTimer.one_shot = true
	meleeAttackTimer.timeout.connect(apply_melee_damage)
	_ensure_walk_animation_loops()
	
	dashAttackTimer.wait_time = dashAttackInterval
	dashAttackTimer.one_shot = true
	dashAttackTimer.start()

func _ensure_walk_animation_loops() -> void:
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
		# Movement cancels melee kick if it was playing.
		if _anim_player.is_playing() and _anim_player.current_animation == String(MELEE_ATTACK_ANIM):
			_anim_player.stop()
			_anim_player.play(WALK_ANIM)
			return
		if _anim_player.current_animation != String(WALK_ANIM) or not _anim_player.is_playing():
			_anim_player.play(WALK_ANIM)
	else:
		if _anim_player.current_animation == String(WALK_ANIM) and _anim_player.is_playing():
			_anim_player.stop()

func InitStat():
	maxPv = GameDifficulty.bossCurrentHealth
	currentPv = maxPv
	moveSpeed = GameDifficulty.bossCurrentMovementSpeed
	
	meleeDamage = GameDifficulty.bossCurrentMeleeDamage
	dashDamage = GameDifficulty.bossCurrentDashDamage
	
	dashAttackInterval = GameDifficulty.bossCurrentDashAttackTiming
	meleeAttackInterval = GameDifficulty.bossCurrentMeleeAttackTiming
	
	UpdateHealthBar()

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if not player:
		return
		
	var distance = global_position.distance_to(player.global_position)
	
	var target_position = player.global_position
	target_position.y = global_position.y
	look_at(target_position, Vector3.UP)
	rotate_y(deg_to_rad(180))

	match current_state:
		State.CHASE:
			handle_chase_state(distance)
		State.MELEE:
			handle_melee_state()
		State.DASH_PREPARE:
			pass
		State.DASH_ATTACK:
			handle_dash_attack(delta)
		State.STUNNED:
			velocity.x = 0
			velocity.z = 0
	
	if !is_on_floor():
		velocity.y = get_gravity().y
		
	move_and_slide()

func handle_chase_state(distance: float) -> void:
	if _is_dead:
		return
	var direction: Vector3 = (player.global_position - global_position).normalized()
	velocity.x = direction.x * moveSpeed
	velocity.z = direction.z * moveSpeed
	_update_walk_animation(true)
	
	if chaseDurationTimer.is_stopped():
		chaseDurationTimer.start()
	
	if distance <= MELEE_RANGE:
		_update_walk_animation(false)
		chaseDurationTimer.stop()
		current_state = State.MELEE


func force_dash_if_chasing() -> void:
	if _is_dead:
		return
	if not player:
		return

	# If we're already in melee range, always prefer melee over dash.
	var distance := global_position.distance_to(player.global_position)
	if distance <= MELEE_RANGE:
		chaseDurationTimer.stop()
		current_state = State.MELEE
		return

	# Optional safety: don't dash if we're too close to get a meaningful dash.
	if distance < DASH_DISTANCE_MIN:
		chaseDurationTimer.start()
		return

	if current_state == State.CHASE:
		if dashAttackTimer.is_stopped():
			handle_dash_prepare()
		else:
			chaseDurationTimer.start()

func handle_melee_state() -> void:
	if _is_dead:
		return
	velocity.x = 0
	velocity.z = 0
	_update_walk_animation(false)
	
	if meleeAttackTimer.is_stopped():
		_play_melee_attack_animation()
		meleeAttackTimer.start(meleeAttackInterval)

func _play_melee_attack_animation() -> void:
	if _anim_player == null:
		return
	if not _anim_player.has_animation(MELEE_ATTACK_ANIM):
		return
	var anim: Animation = _anim_player.get_animation(MELEE_ATTACK_ANIM)
	if anim != null:
		anim.loop_mode = Animation.LOOP_NONE
	_anim_player.stop()
	_anim_player.play(MELEE_ATTACK_ANIM)

func apply_melee_damage():
	if _is_dead:
		return
	if player and global_position.distance_to(player.global_position) <= MELEE_RANGE:
		player.TakeDammage(meleeDamage)
	# Ensure the next time we enter melee we can restart the timer
	# and replay the melee animation.
	if is_instance_valid(meleeAttackTimer):
		meleeAttackTimer.stop()
	current_state = State.CHASE
	
func handle_dash_prepare(_distance: float = 0.0) -> void:
	if _is_dead:
		return
	velocity.x = 0
	velocity.z = 0
	_update_walk_animation(false)
	current_state = State.DASH_PREPARE
	dash_direction = (player.global_position - global_position).normalized()
	
	get_tree().create_timer(0.45).timeout.connect(start_dash_attack)

func start_dash_attack():
	if _is_dead:
		return
	dash_direction = (player.global_position - global_position).normalized()
	current_state = State.DASH_ATTACK
	_play_dash_animation()
	get_tree().create_timer(DASH_ATTACK_DURATION_SEC).timeout.connect(end_dash_attack)

func _play_dash_animation() -> void:
	if _is_dead:
		return
	if _anim_player == null:
		return
	var anim_name: StringName = &""
	if _anim_player.has_animation(DASH_ANIM_PRIMARY):
		anim_name = DASH_ANIM_PRIMARY
	elif _anim_player.has_animation(DASH_ANIM_FALLBACK):
		anim_name = DASH_ANIM_FALLBACK
	elif _anim_player.has_animation(&"Course"):
		anim_name = &"Course"
	else:
		return

	var anim: Animation = _anim_player.get_animation(anim_name)
	var speed: float = 1.0
	if anim != null:
		# Play once, but fast enough to finish during the dash.
		anim.loop_mode = Animation.LOOP_NONE
		if anim.length > 0.0:
			speed = maxf(0.1, anim.length / DASH_ATTACK_DURATION_SEC)
	_anim_player.stop()
	_anim_player.play(anim_name, -1.0, speed, false)

func handle_dash_attack(_delta: float) -> void:
	if _is_dead:
		return
	velocity.x = dash_direction.x * DASH_SPEED
	velocity.z = dash_direction.z * DASH_SPEED
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider is Player:
			apply_dash_damage()
			current_state = State.STUNNED
			end_dash_attack()
			return

func apply_dash_damage():
	if _is_dead:
		return
	if player:
		player.TakeDammage(dashDamage)

func end_dash_attack():
	if _is_dead:
		return
	if current_state == State.CHASE:
		return
	
	current_state = State.STUNNED
	_update_walk_animation(false)
	
	dashAttackTimer.wait_time = dashAttackInterval
	dashAttackTimer.start()
	
	get_tree().create_timer(0.25).timeout.connect(func(): current_state = State.CHASE)

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

	# Stop AI + movement
	current_state = State.STUNNED
	velocity = Vector3.ZERO

	# Stop timers/attacks
	if is_instance_valid(meleeAttackTimer):
		meleeAttackTimer.stop()
	if is_instance_valid(dashAttackTimer):
		dashAttackTimer.stop()
	if is_instance_valid(chaseDurationTimer):
		chaseDurationTimer.stop()

	# Disable collisions while dying
	collision_layer = 0
	collision_mask = 0
	if is_instance_valid(_dynamic_hitbox):
		_dynamic_hitbox.collision_layer = 0
		_dynamic_hitbox.collision_mask = 0

	# Stop all animations and play death
	_update_walk_animation(false)
	var death_time := DEATH_FALLBACK_SEC
	if _anim_player != null and _anim_player.has_animation(DEATH_ANIM):
		_anim_player.stop()
		var anim: Animation = _anim_player.get_animation(DEATH_ANIM)
		if anim != null:
			anim.loop_mode = Animation.LOOP_NONE
			death_time = maxf(0.1, anim.length)
		_anim_player.play(DEATH_ANIM)

	get_tree().create_timer(death_time).timeout.connect(func() -> void:
		if token != _death_token:
			return
		queue_free()
	)

func _layer_bit(layer_number: int) -> int:
	return 1 << (layer_number - 1)
