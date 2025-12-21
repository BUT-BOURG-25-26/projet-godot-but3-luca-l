class_name BonusItem
extends Area3D

const DESPAWN_SECONDS: float = 20.0
const SPIN_DEG_PER_SEC: float = 90.0

enum BonusType { HEAL, SUPER_SPEED, SUPER_ATTACK_SPEED, SUPER_DAMAGE, NUKE }
var currentType: BonusType

var _picked_up: bool = false
var _current_visual: Node3D
var _movement_active: bool = false

@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D

@onready var heal_visual: Node3D = get_node_or_null("Heal") as Node3D
@onready var speed_visual: Node3D = get_node_or_null("SpeedBoost") as Node3D
@onready var damage_visual: Node3D = get_node_or_null("AttPower") as Node3D
@onready var nuke_visual: Node3D = get_node_or_null("Nuke") as Node3D
@onready var attack_speed_visual: Node3D = get_node_or_null("AttackSpeed") as Node3D

@onready var _visual_container: Node = get_node_or_null("VisualRoot") if get_node_or_null("VisualRoot") else self

func _ready() -> void:
	currentType = BonusType.values().pick_random()
	_update_visual_for_type()
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(DESPAWN_SECONDS).timeout.connect(_on_despawn_timeout)
	set_process(true)


func _process(delta: float) -> void:
	if _movement_active:
		return
	if !_current_visual or !is_instance_valid(_current_visual) or !_current_visual.visible:
		return
	_current_visual.rotate_y(deg_to_rad(SPIN_DEG_PER_SEC) * delta)


func _on_despawn_timeout() -> void:
	if _picked_up:
		return
	queue_free()

func _update_visual_for_type() -> void:
	_hide_all_visuals()
	_current_visual = null
	_movement_active = false

	var selected: Node3D = null
	match currentType:
		BonusType.HEAL:
			selected = heal_visual
		BonusType.SUPER_SPEED:
			selected = speed_visual
		BonusType.SUPER_DAMAGE:
			selected = damage_visual
		BonusType.NUKE:
			selected = nuke_visual
		BonusType.SUPER_ATTACK_SPEED:
			# If you don't have a dedicated node yet, we fall back to SpeedBoost.
			selected = attack_speed_visual if attack_speed_visual else speed_visual

	if selected:
		selected.visible = true
		_current_visual = selected
		_apply_attack_speed_tint_if_needed(selected)
		_movement_active = _play_looped_movement_if_needed(selected)
		return

	# Fallback: if no visual node exists, show the base mesh and color it.
	if mesh:
		_hide_all_visuals()
		mesh.visible = true
		setMaterialColor()
		_current_visual = mesh
		_movement_active = false

func _hide_all_visuals() -> void:
	# Hide every Node3D under the visual container.
	# This prevents cases where a node was renamed (not found by get_node_or_null)
	# or when an extra MeshInstance3D is still present and otherwise stays visible.
	for child in _visual_container.get_children():
		if _visual_container == self and child is CollisionShape3D:
			continue
		var node3d := child as Node3D
		if node3d:
			node3d.visible = false

func setMaterialColor() -> void:
	var mat = StandardMaterial3D.new()
	match currentType:
		BonusType.HEAL: mat.albedo_color = Color.GREEN
		BonusType.SUPER_SPEED: mat.albedo_color = Color.YELLOW
		BonusType.SUPER_ATTACK_SPEED: mat.albedo_color = Color.RED
		BonusType.SUPER_DAMAGE: mat.albedo_color = Color.RED
		BonusType.NUKE: mat.albedo_color = Color.BLACK

	mesh.material_override = mat

func _play_looped_movement_if_needed(visual_root: Node) -> bool:
	if currentType != BonusType.SUPER_SPEED and currentType != BonusType.SUPER_ATTACK_SPEED and currentType != BonusType.NUKE:
		return false

	# Imported GLB animations are usually exposed via an AnimationPlayer somewhere under the instance.
	var anim_players: Array[Node] = visual_root.find_children("*", "AnimationPlayer", true, false)
	if anim_players.is_empty():
		return false

	var anim_player := anim_players[0] as AnimationPlayer
	if anim_player == null:
		return false
	if !anim_player.has_animation("Movement"):
		return false

	var anim: Animation = anim_player.get_animation("Movement")
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR
	anim_player.play("Movement")
	return true

func _apply_attack_speed_tint_if_needed(visual_root: Node) -> void:
	if currentType != BonusType.SUPER_ATTACK_SPEED:
		return

	# Godot 4: 3D nodes don't have CanvasItem-style `modulate`.
	# Use a semi-transparent overlay material to tint without destroying the GLB materials/textures.
	var overlay := StandardMaterial3D.new()
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.albedo_color = Color(1.0, 0.0, 0.0, 0.35)
	overlay.blend_mode = BaseMaterial3D.BLEND_MODE_MIX

	var geometries: Array[Node] = visual_root.find_children("*", "GeometryInstance3D", true, false)
	for node in geometries:
		var geometry := node as GeometryInstance3D
		if geometry:
			geometry.material_overlay = overlay


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_picked_up = true
		body.ApplyBonus(currentType)
		queue_free()
