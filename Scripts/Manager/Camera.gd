class_name Camera
extends Camera3D

@export var offset: Vector3 = Vector3(0.8, 6.0 ,6.7)
@export var cameraRotation: float = -45
var player : Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	global_position = player.global_position + offset
	look_at(player.global_position, Vector3.UP)
	rotation_degrees.x = cameraRotation
