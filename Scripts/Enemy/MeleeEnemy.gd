class_name MeleeEnemy
extends Enemy

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
	
	var random_offset = randf_range(0.0, 1.0)
	await get_tree().create_timer(random_offset).timeout
	meleeAttackTimer.start(meleeAttackInterval)
	meleeAttackTimer.timeout.connect(Attack)
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)

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

func _on_damage_area_body_entered(body: Node3D) -> void:
	if body is Player and !targets_in_range.has(body):
		targets_in_range.append(body)

func _on_damage_area_body_exited(body: Node3D) -> void:
	if body is Player:
		targets_in_range.erase(body)
