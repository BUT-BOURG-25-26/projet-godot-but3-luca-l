extends ProgressBar

func update(newValue: int):
	value = newValue
	print("progress bar : " + str(value))
	
func barAnimation (animationPath) -> void:
	animationPath.play("progressbarUpdated")
	return
