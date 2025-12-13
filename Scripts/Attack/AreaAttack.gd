class_name AreaAttack
extends Area3D

var attackInterval: float
@onready var attackTimer:Timer = $Timers/AttackTimer
var damage: float

func _ready() -> void:
	attackTimer.start(attackInterval)
	attackTimer.timeout.connect(DetectCollision)

func DetectCollision() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Enemy:
			body.TakeDammage(damage)
