class_name RangeEnemy
extends Enemy

# Attack Timer
var rangeAttackInterval: float
@onready var rangeAttackTimer:Timer = $Timers/RangeAttackTimer

var projectilSpeed: float
var isCloseEnoughToPlayer: bool = false

# Attack Scenes
@export var rangeAttackScene: PackedScene

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Player
	healthbar = $HealthBarSprite/SubViewport/CanvasLayer/HealthBar
	InitStat()
	
	var random_offset = randf_range(0.0, 1.0)
	await get_tree().create_timer(random_offset).timeout
	rangeAttackTimer.start(rangeAttackInterval)
	rangeAttackTimer.timeout.connect(Attack)


func Attack()->void:
	if !isCloseEnoughToPlayer:
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
		
	move_and_slide()
