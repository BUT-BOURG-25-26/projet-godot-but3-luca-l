class_name RangeEnemy
extends Enemy

# Layers (project: layer_1 = Map, layer_2 = Player, layer_3 = Enemy)
const MAP_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 3
const DEFAULT_LAYER := 1 # fallback if Player is still on default layer

# Attack Timer
var rangeAttackInterval: float
@onready var rangeAttackTimer:Timer = $Timers/RangeAttackTimer

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
	
	var random_offset = randf_range(0.0, 1.0)
	await get_tree().create_timer(random_offset).timeout
	rangeAttackTimer.wait_time = rangeAttackInterval
	if !rangeAttackTimer.timeout.is_connected(Attack):
		rangeAttackTimer.timeout.connect(Attack)
	rangeAttackTimer.start()


func Attack()->void:
	if !isCloseEnoughToPlayer:
		return
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


func InitStat():
	maxPv = GameDifficulty.rangeCurrentHealth
	currentPv = maxPv
	moveSpeed = GameDifficulty.rangeCurrentMovementSpeed
	damage = GameDifficulty.rangeCurrentDammage
	rangeAttackInterval = GameDifficulty.rangeCurrentAttackTiming
	projectilSpeed = GameDifficulty.rangeCurrentProjectilSpeed
	UpdateHealthBar()

func _physics_process(delta: float) -> void:
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
		else:
			isCloseEnoughToPlayer = true
			velocity.x = 0
			velocity.z = 0

		if !is_on_floor():
			velocity.y = get_gravity().y
	else:
		# Re-try player acquisition if it wasn't ready at spawn time
		player = get_tree().get_first_node_in_group("Player") as Player
		if player == null and Engine.has_singleton("GameManager") and GameManager.player:
			player = GameManager.player
		velocity = Vector3.ZERO

	move_and_slide()

func _layer_bit(layer_number: int) -> int:
	return 1 << (layer_number - 1)
