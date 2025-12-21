class_name AreaAttack
extends Area3D

@export var loop_animation_name: StringName = &"Take 001"
@export var loop_from_sec: float = 1.0
@export var loop_to_sec: float = 7.0

var attackInterval: float
@onready var attackTimer:Timer = $Timers/AttackTimer
var damage: float

var _anim_player: AnimationPlayer

func _ready() -> void:
	_anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _anim_player == null:
		_anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim_player != null and _anim_player.has_animation(loop_animation_name) and loop_to_sec > loop_from_sec:
		_anim_player.play(loop_animation_name)
		_anim_player.seek(loop_from_sec, true)
		set_process(true)
	else:
		set_process(false)

	attackTimer.start(attackInterval)
	attackTimer.timeout.connect(DetectCollision)

func _process(_delta: float) -> void:
	if _anim_player == null:
		return
	if _anim_player.current_animation != String(loop_animation_name):
		return
	if _anim_player.current_animation_position >= loop_to_sec:
		_anim_player.seek(loop_from_sec, true)

func DetectCollision() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Enemy:
			body.TakeDammage(damage)
