class_name BossEnemy
extends Enemy

const DASH_DISTANCE_MIN: float = 2
const MELEE_RANGE: float = 1.5
const DASH_SPEED: float = 20.0

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

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Player
	healthbar = $HealthBarSprite/SubViewport/CanvasLayer/HealthBar
	InitStat()
	
	chaseDurationTimer.wait_time = MAX_CHASE_TIME
	chaseDurationTimer.one_shot = true
	chaseDurationTimer.timeout.connect(force_dash_if_chasing)
	add_child(chaseDurationTimer)
	
	var random_offset = randf_range(0.0, 1.0)
	await get_tree().create_timer(random_offset).timeout
	
	meleeAttackTimer.timeout.connect(apply_melee_damage)
	
	dashAttackTimer.wait_time = dashAttackInterval
	dashAttackTimer.one_shot = true
	dashAttackTimer.start()

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
	var direction: Vector3 = (player.global_position - global_position).normalized()
	velocity.x = direction.x * moveSpeed
	velocity.z = direction.z * moveSpeed
	
	if chaseDurationTimer.is_stopped():
		chaseDurationTimer.start()
	
	if distance <= MELEE_RANGE:
		chaseDurationTimer.stop()
		current_state = State.MELEE


func force_dash_if_chasing() -> void:
	if current_state == State.CHASE:
		if dashAttackTimer.is_stopped():
			handle_dash_prepare()
		else:
			chaseDurationTimer.start()

func handle_melee_state() -> void:
	velocity.x = 0
	velocity.z = 0
	
	if meleeAttackTimer.is_stopped():
		meleeAttackTimer.start(meleeAttackInterval)

func apply_melee_damage():
	if player and global_position.distance_to(player.global_position) <= MELEE_RANGE:
		player.TakeDammage(meleeDamage)
	current_state = State.CHASE
	
func handle_dash_prepare(_distance: float = 0.0) -> void:
	velocity.x = 0
	velocity.z = 0
	current_state = State.DASH_PREPARE
	dash_direction = (player.global_position - global_position).normalized()
	
	get_tree().create_timer(0.45).timeout.connect(start_dash_attack)

func start_dash_attack():
	dash_direction = (player.global_position - global_position).normalized()
	current_state = State.DASH_ATTACK
	get_tree().create_timer(0.75).timeout.connect(end_dash_attack)

func handle_dash_attack(_delta: float) -> void:
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
	if player:
		player.TakeDammage(dashDamage)

func end_dash_attack():
	if current_state == State.CHASE:
		return
	
	current_state = State.STUNNED
	
	dashAttackTimer.wait_time = dashAttackInterval
	dashAttackTimer.start()
	
	get_tree().create_timer(0.25).timeout.connect(func(): current_state = State.CHASE)
