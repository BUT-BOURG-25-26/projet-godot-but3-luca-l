class_name PauseMenu
extends CanvasLayer

const GAME_OVER_SFX_PATH := "res://Assets/Sons/gameover.wav"

var _game_over_sfx_played: bool = false

@onready var resumeButton: Button = $Control/MarginContainer/VBoxContainer/TopButton

@onready var meleeDamagePG: ProgressBar = $Control/PanelContainer/VBoxContainer/MeleeDamage/ProgressBar
@onready var RangeDamagePG: ProgressBar = $Control/PanelContainer/VBoxContainer/RangeDamage/ProgressBar
@onready var AreaDamagePG: ProgressBar = $Control/PanelContainer/VBoxContainer/AreaDamage/ProgressBar
@onready var MovementSpeedPG: ProgressBar = $Control/PanelContainer/VBoxContainer/MovementSpeed/ProgressBar


func _ready() -> void:
	if meleeDamagePG:
		meleeDamagePG.max_value = PlayerStatManager.maxMeleeDammage
	if AreaDamagePG:
		AreaDamagePG.max_value = PlayerStatManager.maxAreaDammage
	if RangeDamagePG:
		RangeDamagePG.max_value = PlayerStatManager.maxRangeDammage
	if MovementSpeedPG:
		MovementSpeedPG.max_value = PlayerStatManager.maxMovementSpeed
	UpdateProgressBars()
	hide()
	_game_over_sfx_played = false

func open_pause_menu() -> void:
	# Avoid re-triggering while already open (GameManager can call this every frame on game over).
	if visible:
		return

	if GameManager.gameOver:
		resumeButton.visible = false
		if !_game_over_sfx_played:
			_game_over_sfx_played = true
			_play_game_over_sfx()
	else:
		resumeButton.visible = true
		_game_over_sfx_played = false

	show()
	get_tree().paused = true
	
func onResumeButtonPressed() -> void:
	hide()
	get_tree().paused = false
	_game_over_sfx_played = false

func onRestartButtonPressed() -> void:
	get_tree().paused = false
	_game_over_sfx_played = false
	GameManager.resetData()
	GameDifficulty.resetData()
	PlayerStatManager.resetData()
	get_tree().reload_current_scene()

func onMenuButtonPressed() -> void:
	get_tree().paused = false
	_game_over_sfx_played = false
	GameManager.resetData()
	GameDifficulty.resetData()
	PlayerStatManager.resetData()
	get_tree().change_scene_to_file("res://Scenes/UI/startMenu.tscn")


func _play_game_over_sfx() -> void:
	var sfx_stream := load(GAME_OVER_SFX_PATH) as AudioStream
	if sfx_stream == null:
		push_warning("PauseMenu: impossible de charger %s" % GAME_OVER_SFX_PATH)
		return
	var player := AudioStreamPlayer.new()
	player.stream = sfx_stream
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func UpdateProgressBars():
	if meleeDamagePG:
		meleeDamagePG.value = PlayerStatManager.currentMeleeDammage
	if AreaDamagePG:
		AreaDamagePG.value = PlayerStatManager.currentAreaDammage
	if RangeDamagePG:
		RangeDamagePG.value = PlayerStatManager.currentRangeDammage
	if MovementSpeedPG:
		MovementSpeedPG.value = PlayerStatManager.currentMovementSpeed
	
