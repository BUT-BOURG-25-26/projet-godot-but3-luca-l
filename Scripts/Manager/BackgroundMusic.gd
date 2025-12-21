extends AudioStreamPlayer

@export var auto_play: bool = true
@export var loop: bool = true

const TRACKS: Array[String] = [
	"res://Assets/Sons/Gym Grinder.mp3",
	"res://Assets/Sons/Survivor Circuit.mp3",
	"res://Assets/Sons/Steel Resolve.mp3",
]

var _current_track_index: int = -1

func _ready() -> void:
	# Keep music running even if the game is paused by menus.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Listen to wave/level changes (GameManager is an AutoLoad Node).
	if is_instance_valid(GameManager) and GameManager.has_signal("game_level_changed"):
		if !GameManager.game_level_changed.is_connected(_on_game_level_changed):
			GameManager.game_level_changed.connect(_on_game_level_changed)
		_on_game_level_changed(GameManager.gameLevel)

	if loop and stream:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

	if auto_play and !playing:
		play()

func _on_game_level_changed(new_level: int) -> void:
	# Every 10 waves: 1-10 -> 0, 11-20 -> 1, 21-30 -> 2, then repeat.
	var index := int(floor(float(max(new_level, 1) - 1) / 10.0)) % TRACKS.size()
	if index == _current_track_index:
		return
	_current_track_index = index

	var new_stream: AudioStream = load(TRACKS[index]) as AudioStream
	if new_stream == null:
		push_warning("BackgroundMusic: impossible de charger %s" % TRACKS[index])
		return
	stream = new_stream
	if loop and stream and stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	if auto_play:
		play()
