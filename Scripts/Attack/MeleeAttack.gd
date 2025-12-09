class_name MeleeAttack
extends Area3D

@export var lifeDuration: float = 0.5
@onready var lifeTimeTimer:Timer = $Timers/Lifetime
@export var damage = 3
	
func DetectCollision() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Enemy:
			body.TakeDammage(damage)

func Destroy() -> void:
	DetectCollision()
	queue_free()

func _ready() -> void:
	lifeTimeTimer.start(lifeDuration)
	lifeTimeTimer.timeout.connect(Destroy)
