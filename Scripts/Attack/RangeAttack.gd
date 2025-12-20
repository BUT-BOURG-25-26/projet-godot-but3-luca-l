class_name RangeAttack
extends Area3D

var isEnemyATarget: bool = true
var speed: float = 15
var direction: Vector3 = Vector3.FORWARD
var damage: float

@onready var _anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
var _loop_anim_name: StringName = &""

func _ready():
	body_entered.connect(_on_body_entered)
	_start_attack_animation_loop()

func _start_attack_animation_loop() -> void:
	if _anim_player == null:
		return

	_loop_anim_name = _pick_attack_animation_name(_anim_player)
	if _loop_anim_name == &"":
		return

	var anim: Animation = _anim_player.get_animation(_loop_anim_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR

	if not _anim_player.animation_finished.is_connected(_on_animation_finished):
		_anim_player.animation_finished.connect(_on_animation_finished)

	_anim_player.play(_loop_anim_name)

func _on_animation_finished(anim_name: StringName) -> void:
	if _anim_player == null:
		return
	if _loop_anim_name == &"":
		return
	if anim_name == _loop_anim_name:
		_anim_player.play(_loop_anim_name)

func _pick_attack_animation_name(anim_player: AnimationPlayer) -> StringName:
	if anim_player.has_animation(&"Attaque"):
		return &"Attaque"
	if anim_player.has_animation(&"attaque"):
		return &"attaque"

	for name in anim_player.get_animation_list():
		if String(name).to_lower() == "attaque":
			return name
	for name in anim_player.get_animation_list():
		if String(name).to_lower().ends_with("/attaque"):
			return name

	var all_anims := anim_player.get_animation_list()
	if not all_anims.is_empty():
		return all_anims[0]
	return &""

func InitTargetToAttack() -> void:
	var target: Node3D
	if isEnemyATarget:
		target = find_nearest_enemy()
	else:
		target = find_nearest_player()
	if target:
		direction = (target.global_position - global_position).normalized()
		look_at(target.global_position, Vector3.UP)
	else:
		queue_free()
		direction = -global_transform.basis.z
	
func _on_body_entered(body: Node3D) -> void:
	if isEnemyATarget && body is Enemy:
		body.TakeDammage(damage)
		queue_free()
	elif !isEnemyATarget && body is Player:
		body.TakeDammage(damage)
		queue_free()
	elif !isEnemyATarget && body is Enemy:
		return
	elif isEnemyATarget && body is Player:
		return
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

func find_nearest_player() -> Node3D:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player
	else: 
		return null
