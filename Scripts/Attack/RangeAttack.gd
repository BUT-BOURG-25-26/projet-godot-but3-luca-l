class_name RangeAttack
extends Area3D

@export var speed: float = 20.0
var direction: Vector3 = Vector3.FORWARD
@export var damage = 1

func _ready():
	body_entered.connect(_on_body_entered)

func InitTargetToAttack() -> void:
	var target = find_nearest_enemy()
	if target:
		direction = (target.global_position - global_position).normalized()
		look_at(target.global_position, Vector3.UP)
	else:
		queue_free()
		direction = -global_transform.basis.z
	
func _on_body_entered(body: Node3D) -> void:
	if body is Enemy:
		body.TakeDammage(damage)
		queue_free()
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
