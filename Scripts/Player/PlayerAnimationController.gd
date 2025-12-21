class_name PlayerAnimationController
extends Node

@export var animation_player: AnimationPlayer

const MELEE_ANIM_NAME := "Attaque_melee"
const WALK_ANIM_NAME := "Marche"
const RUN_ANIM_NAME := "Course"
const PUSHUP_PREP_ANIM_NAME := "Preparation_pompe"
const PUSHUP_ANIM_NAME := "Pompe"
const RUN_SPEED_THRESHOLD := 15.0
const MELEE_CUTOFF_SECONDS := 1.4
var melee_anim_length := 0.0
var melee_anim_speed := 1.0
var melee_anim_available := false
var _melee_anim_running := false
var walk_anim_available := false
var run_anim_available := false
var _current_movement_anim := ""
var _melee_cutoff_timer: SceneTreeTimer
var pushup_prep_available := false
var pushup_anim_available := false
var _pushup_sequence_running := false
var pushup_cycles_target := 3
var _remaining_pushups := 0
var _external_animation_lock := false

func setup(anim_player: AnimationPlayer) -> void:
	animation_player = anim_player
	if animation_player == null:
		push_warning("AnimationPlayer non défini pour PlayerAnimationController")
		melee_anim_available = false
		return
	if !animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	_init_melee_animation()
	_init_movement_animations()
	_init_pushup_animations()

func set_animation_lock(locked: bool) -> void:
	_external_animation_lock = locked
	if locked:
		cancel_all()

func is_animation_locked() -> bool:
	return _external_animation_lock

func cancel_all() -> void:
	_clear_melee_cutoff_timer()
	_melee_anim_running = false
	_pushup_sequence_running = false
	_remaining_pushups = 0
	_current_movement_anim = ""
	if animation_player:
		animation_player.stop()

func update_melee_interval(interval: float) -> void:
	if !melee_anim_available:
		melee_anim_speed = 1.0
		return
	var clamped := maxf(interval, 0.01)
	melee_anim_speed = clampf(melee_anim_length / clamped, 0.5, 3.0)

func is_melee_attack_active() -> bool:
	return _melee_anim_running

func is_pushup_active() -> bool:
	return _pushup_sequence_running

func try_play_melee_attack(interval: float) -> bool:
	if _external_animation_lock:
		return false
	if !melee_anim_available or animation_player == null or _melee_anim_running or _pushup_sequence_running:
		return false
	update_melee_interval(interval)
	animation_player.play(MELEE_ANIM_NAME, -1.0, melee_anim_speed)
	animation_player.seek(0.0, true)
	_melee_anim_running = true
	_current_movement_anim = ""
	_schedule_melee_cutoff_timer()
	return true

func reset_melee_attack_state() -> void:
	_finish_melee_animation()

func trigger_pushup_sequence() -> bool:
	if animation_player == null:
		return false
	if _external_animation_lock:
		return false
	if _pushup_sequence_running or _melee_anim_running:
		return false
	if !pushup_prep_available or !pushup_anim_available:
		return false
	_pushup_sequence_running = true
	_remaining_pushups = pushup_cycles_target
	_current_movement_anim = ""
	animation_player.play(PUSHUP_PREP_ANIM_NAME)
	animation_player.seek(0.0, true)
	return true

func _init_melee_animation() -> void:
	if animation_player == null:
		return
	melee_anim_available = animation_player.has_animation(MELEE_ANIM_NAME)
	if melee_anim_available:
		melee_anim_length = animation_player.get_animation(MELEE_ANIM_NAME).length
		update_melee_interval(1.0)
	else:
		push_warning("Animation '%s' introuvable pour PlayerAnimationController" % MELEE_ANIM_NAME)

func _init_movement_animations() -> void:
	if animation_player == null:
		return
	walk_anim_available = animation_player.has_animation(WALK_ANIM_NAME)
	run_anim_available = animation_player.has_animation(RUN_ANIM_NAME)
	if !walk_anim_available:
		push_warning("Animation '%s' introuvable pour PlayerAnimationController" % WALK_ANIM_NAME)
	if !run_anim_available:
		push_warning("Animation '%s' introuvable pour PlayerAnimationController" % RUN_ANIM_NAME)

func _init_pushup_animations() -> void:
	if animation_player == null:
		return
	pushup_prep_available = animation_player.has_animation(PUSHUP_PREP_ANIM_NAME)
	pushup_anim_available = animation_player.has_animation(PUSHUP_ANIM_NAME)
	if !pushup_prep_available:
		push_warning("Animation '%s' introuvable pour PlayerAnimationController" % PUSHUP_PREP_ANIM_NAME)
	if !pushup_anim_available:
		push_warning("Animation '%s' introuvable pour PlayerAnimationController" % PUSHUP_ANIM_NAME)

func update_movement_animation(is_moving: bool, move_speed: float) -> void:
	if animation_player == null:
		return
	if _external_animation_lock:
		return
	if _melee_anim_running or _pushup_sequence_running:
		return
	var target_anim := ""
	if is_moving:
		if move_speed > RUN_SPEED_THRESHOLD and run_anim_available:
			target_anim = RUN_ANIM_NAME
		elif walk_anim_available:
			target_anim = WALK_ANIM_NAME
	if target_anim == "":
		if _current_movement_anim != "":
			animation_player.stop()
			_current_movement_anim = ""
		return
	if _current_movement_anim == target_anim:
		return
	animation_player.play(target_anim)
	_current_movement_anim = target_anim

func _on_animation_finished(anim_name: StringName) -> void:
	if _external_animation_lock:
		return
	if anim_name == MELEE_ANIM_NAME:
		_finish_melee_animation()
		return
	if !_pushup_sequence_running:
		return
	if anim_name == PUSHUP_PREP_ANIM_NAME:
		_play_pushup_main()
	elif anim_name == PUSHUP_ANIM_NAME:
		_remaining_pushups -= 1
		if _remaining_pushups > 0:
			_play_pushup_main()
		else:
			_finish_pushup_sequence()

func _play_pushup_main() -> void:
	if animation_player == null or !pushup_anim_available:
		_finish_pushup_sequence()
		return
	if _remaining_pushups <= 0:
		_finish_pushup_sequence()
		return
	animation_player.play(PUSHUP_ANIM_NAME)
	animation_player.seek(0.0, true)

func _finish_pushup_sequence() -> void:
	_pushup_sequence_running = false
	_remaining_pushups = 0
	_current_movement_anim = ""

func _schedule_melee_cutoff_timer() -> void:
	if melee_anim_length <= 0.0:
		return
	var cutoff: float = min(MELEE_CUTOFF_SECONDS, melee_anim_length)
	if cutoff <= 0.0:
		return
	_clear_melee_cutoff_timer()
	var speed: float = melee_anim_speed if melee_anim_speed != 0.0 else 1.0
	var wait_time: float = cutoff / speed
	_melee_cutoff_timer = get_tree().create_timer(wait_time)
	_melee_cutoff_timer.timeout.connect(_on_melee_cutoff_timeout)

func _clear_melee_cutoff_timer() -> void:
	if _melee_cutoff_timer:
		if is_instance_valid(_melee_cutoff_timer):
			if _melee_cutoff_timer.timeout.is_connected(_on_melee_cutoff_timeout):
				_melee_cutoff_timer.timeout.disconnect(_on_melee_cutoff_timeout)
		_melee_cutoff_timer = null

func _on_melee_cutoff_timeout() -> void:
	_melee_cutoff_timer = null
	if !_melee_anim_running or animation_player == null:
		return
	animation_player.stop()
	_finish_melee_animation()

func _finish_melee_animation() -> void:
	_clear_melee_cutoff_timer()
	_melee_anim_running = false
	_current_movement_anim = ""
