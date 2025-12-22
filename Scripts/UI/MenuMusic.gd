extends AudioStreamPlayer

@export var auto_play: bool = true
@export var loop: bool = true

func _ready() -> void:
	# Keep music running even if the game is paused by menus.
	process_mode = Node.PROCESS_MODE_ALWAYS

	if loop and stream:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

	if auto_play and !playing:
		play()
