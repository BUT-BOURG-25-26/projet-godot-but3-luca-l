class_name RangeAttack
extends Area3D

var isEnemyATarget: bool = true
var speed: float = 15
var direction: Vector3 = Vector3.FORWARD
var damage: float

func _ready():
	body_entered.connect(_on_body_entered)

func InitTargetToAttack() -> void:
	var target: Node3D
	if isEnemyATarget:
		target = find_nearest_enemy()
	else:
		target = find_nearest_player()
	if target:
		direction = (target.global_position - global_position).normalized()
		look_at(target.global_position, Vector3.UP)
	else:
		queue_free()
		direction = -global_transform.basis.z
	
func _on_body_entered(body: Node3D) -> void:
	if isEnemyATarget && body is Enemy:
		body.TakeDammage(damage)
		queue_free()
	elif !isEnemyATarget && body is Player:
		body.TakeDammage(damage)
		queue_free()
	elif !isEnemyATarget && body is Enemy:
		return
	elif isEnemyATarget && body is Player:
		return
	else:
		queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func find_nearest_enemy() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty():
		return null
	
	var nearest_enemy: Node3D = null
	var min_distance: float = INF

	for enemy in enemies:
		var distance = global_position.distance_squared_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy

	return nearest_enemy

func find_nearest_player() -> Node3D:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player
	else: 
		return null
