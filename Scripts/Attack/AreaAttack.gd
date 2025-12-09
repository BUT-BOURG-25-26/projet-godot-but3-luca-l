class_name AreaAttack
extends Area3D

@export var damageTiming: float = 1.5
@onready var attackTimer:Timer = $Timers/AttackTimer
@export var damage = 1

func _ready() -> void:
	attackTimer.start(damageTiming)
	attackTimer.timeout.connect(DetectCollision)

func DetectCollision() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Enemy:
			body.TakeDammage(damage)
