class_name MeleeEnemy
extends Enemy

# Layers (project: layer_1 = Map, layer_2 = Player, layer_3 = Enemy)
const MAP_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 3
const DEFAULT_LAYER := 1 # fallback if Player is still on default layer

# Animations
const WALK_ANIM_NAME := "Marche"
const WALK_BASE_SPEED := 5.0
const WALK_SPEED_MIN := 1.0
const WALK_SPEED_MAX := 2.5
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var _current_anim := ""
var _walk_anim_available := false

# Attack Timer
var meleeAttackInterval: float
@onready var meleeAttackTimer:Timer = $Timers/MeleAttackTimer
@onready var damage_area: Area3D = $DamageArea

var targets_in_range: Array[Player] = []

func _ready() -> void:
	healthbar = $HealthBarSprite/SubViewport/CanvasLayer/HealthBar
	player = get_tree().get_first_node_in_group("Player") as Player
	InitStat()
	UpdateHealthBar()

	# Force correct collision layers/masks so collisions work with map + player, allow enemy-enemy bumping, and DamageArea detects the player
	collision_layer = _layer_bit(ENEMY_LAYER)
	collision_mask = _layer_bit(PLAYER_LAYER) | _layer_bit(MAP_LAYER) | _layer_bit(DEFAULT_LAYER) | _layer_bit(ENEMY_LAYER)
	damage_area.collision_layer = 0 # Area itself does not need to be detected by others
	damage_area.collision_mask = _layer_bit(PLAYER_LAYER) | _layer_bit(DEFAULT_LAYER)
	damage_area.monitoring = true
	damage_area.monitorable = false
	
	var random_offset = randf_range(0.0, 1.0)
	await get_tree().create_timer(random_offset).timeout
	meleeAttackTimer.wait_time = meleeAttackInterval
	if !meleeAttackTimer.timeout.is_connected(Attack):
		meleeAttackTimer.timeout.connect(Attack)
	meleeAttackTimer.start()
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)

	_walk_anim_available = anim_player and anim_player.has_animation(WALK_ANIM_NAME)

func InitStat():
	maxPv = GameDifficulty.meleeCurrentHealth
	currentPv = maxPv
	moveSpeed = GameDifficulty.meleeCurrentMovementSpeed
	damage = GameDifficulty.meleeCurrentDammage
	meleeAttackInterval = GameDifficulty.meleeCurrentAttackTiming
	UpdateHealthBar()

func Attack()->void:
	if targets_in_range.is_empty():
		return
	var alive_targets: Array[Player] = []
	for target in targets_in_range:
		if target and is_instance_valid(target):
			target.TakeDammage(damage)
			alive_targets.append(target)
	targets_in_range = alive_targets
	
func _physics_process(delta: float) -> void:
	if player:
		var direction: Vector3 = (player.global_position - global_position).normalized()
		velocity.x = direction.x * moveSpeed
		velocity.z = direction.z * moveSpeed

		if !is_on_floor():
			velocity.y = get_gravity().y
		
		var target_position = player.global_position
		target_position.y = global_position.y 
		
		look_at(target_position, Vector3.UP)
		rotate_y(deg_to_rad(180))
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()

	_update_walk_animation()
	velocity = Vector3.ZERO

func _on_damage_area_body_entered(body: Node3D) -> void:
	if body is Player and !targets_in_range.has(body):
		targets_in_range.append(body)

func _on_damage_area_body_exited(body: Node3D) -> void:
	if body is Player:
		targets_in_range.erase(body)

func _layer_bit(layer_number: int) -> int:
	return 1 << (layer_number - 1)

func _update_walk_animation() -> void:
	if !_walk_anim_available or anim_player == null:
		return
	var speed_scale := clampf(moveSpeed / WALK_BASE_SPEED, WALK_SPEED_MIN, WALK_SPEED_MAX)
	anim_player.speed_scale = speed_scale
	anim_player.play(WALK_ANIM_NAME, -1.0, speed_scale)
	_current_anim = WALK_ANIM_NAME
