class_name MeleeAttack
extends Area3D

# Layers (project: layer_1 = Map, layer_2 = Player, layer_3 = Enemy)
const PLAYER_LAYER := 2
const ENEMY_LAYER := 3

@export var lifeDuration: float = 0.5
@export_range(0.0, 1.0, 0.01) var visible_from_ratio: float = 0.5
@onready var lifeTimeTimer:Timer = $Timers/Lifetime
var damage: float

var _scene_basis: Basis

func _ready() -> void:
	_scene_basis = transform.basis

	# Visuals: only visible from half of the attack to the end.
	visible = false
	var show_delay := maxf(0.0, lifeDuration * visible_from_ratio)
	get_tree().create_timer(show_delay).timeout.connect(func() -> void:
		if is_instance_valid(self):
			visible = true
	)

	# Ensure overlaps work even if the scene/model was replaced.
	monitoring = true
	collision_layer = _layer_bit(PLAYER_LAYER)
	collision_mask = _layer_bit(ENEMY_LAYER)

	lifeTimeTimer.start(lifeDuration)
	lifeTimeTimer.timeout.connect(Destroy)

func set_attack_direction(direction: Vector3) -> void:
	if _scene_basis == Basis():
		_scene_basis = transform.basis

	var dir := direction
	dir.y = 0.0
	if dir == Vector3.ZERO:
		return
		
	dir = dir.normalized()
	# Match `look_at()` behavior: Godot considers -Z as forward.
	var yaw := atan2(-dir.x, -dir.z)
	var yaw_basis := Basis(Vector3.UP, yaw)
	var desired_basis := yaw_basis * _scene_basis
	global_transform = Transform3D(desired_basis, global_transform.origin)

func DetectCollision() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Enemy:
			body.TakeDammage(damage)

func Destroy() -> void:
	DetectCollision()
	queue_free()

func _layer_bit(layer_number: int) -> int:
	return 1 << (layer_number - 1)
