class_name MeleeAttack
extends Area3D

var dammage = 5
@export var lifeDuration: float = 0.5
@onready var lifeTimeTimer:Timer = $Timers/Lifetime

func _ready() -> void:
	lifeTimeTimer.start(lifeDuration)
	lifeTimeTimer.timeout.connect(Destroy)
	
func DetectCollision() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Enemy:
			body.takeDammage(dammage)
	
func Destroy() -> void:
	DetectCollision()
	queue_free()
