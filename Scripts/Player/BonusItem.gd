class_name BonusItem
extends Area3D

enum BonusType { HEAL, SUPER_SPEED, SUPER_ATTACK_SPEED, SUPER_DAMAGE, NUKE }
var currentType: BonusType

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	currentType = BonusType.values().pick_random()
	setMaterialColor()
	body_entered.connect(_on_body_entered)

func setMaterialColor():
	var mat = StandardMaterial3D.new()
	match currentType:
		BonusType.HEAL: mat.albedo_color = Color.GREEN
		BonusType.SUPER_SPEED: mat.albedo_color = Color.YELLOW
		BonusType.SUPER_ATTACK_SPEED: mat.albedo_color = Color.BLUE
		BonusType.SUPER_DAMAGE: mat.albedo_color = Color.RED
		BonusType.NUKE: mat.albedo_color = Color.BLACK
	
	if mesh:
		mesh.material_override = mat


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.ApplyBonus(currentType)
		queue_free()
