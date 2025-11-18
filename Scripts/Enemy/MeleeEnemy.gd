class_name MeleeEnemy
extends Enemy

# Attack Timer
@export var meleeAttackInterval: float = 1
@onready var meleeAttackTimer:Timer = $Timers/MeleAttackTimer

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player") as Player
	meleeAttackTimer.start(meleeAttackInterval)
	meleeAttackTimer.timeout.connect(Attack)

func Attack()->void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider is Player:
			collider.TakeDammage(dammage)
	
func _physics_process(delta: float) -> void:
	if player:
		var direction: Vector3 = (player.global_position - global_position).normalized()
		velocity.x = direction.x * moveSpeed
		velocity.z = direction.z * moveSpeed

		if !is_on_floor():
			velocity.y = get_gravity().y
	
	if player:
		var target_position = player.global_position
		target_position.y = global_position.y 
		
		look_at(target_position, Vector3.UP)
		rotate_y(deg_to_rad(180))
	move_and_slide()
