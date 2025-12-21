class_name RangeAttack
extends Area3D

var isEnemyATarget: bool = true
var speed: float = 15
var direction: Vector3 = Vector3.FORWARD
var damage: float

var _has_target: bool = false
var _spawn_ms: int = 0
var _max_lifetime_ms: int = 3000

@export var spin_speed_deg_per_sec: float = 720.0

@onready var _spin_node: Node3D = (find_child("Sketchfab_Scene", true, false) as Node3D)

@onready var _anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
var _loop_anim_name: StringName = &""

func _ready():
	_spawn_ms = Time.get_ticks_msec()
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
		_has_target = true
		direction = (target.global_position - global_position).normalized()
		look_at(target.global_position, Vector3.UP)
	else:
		_has_target = false
		direction = -global_transform.basis.z
		if not isEnemyATarget:
			queue_free()
	
func _on_body_entered(body: Node3D) -> void:
	if isEnemyATarget:
		if body is Enemy:
			body.TakeDammage(damage)
			queue_free()
			return
		if body is Player:
			return
		# Projectile du joueur : on ignore les collisions non-Enemy pour éviter
		# de disparaître instantanément (sol, décor, etc.).
		return

	# Projectile ennemi (cible: Player) : comportement strict comme avant.
	if body is Player:
		body.TakeDammage(damage)
		queue_free()
		return
	if body is Enemy:
		return
	queue_free()

func _physics_process(delta):
	if isEnemyATarget and _spawn_ms != 0 and Time.get_ticks_msec() - _spawn_ms > _max_lifetime_ms:
		queue_free()
		return

	if isEnemyATarget:
		var node_to_spin: Node3D = _spin_node if _spin_node != null else self
		node_to_spin.rotate_object_local(Vector3(0, 0, 1), deg_to_rad(spin_speed_deg_per_sec) * delta)

	if isEnemyATarget and not _has_target:
		var target := find_nearest_enemy()
		if target:
			_has_target = true
			direction = (target.global_position - global_position).normalized()
			look_at(target.global_position, Vector3.UP)

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
