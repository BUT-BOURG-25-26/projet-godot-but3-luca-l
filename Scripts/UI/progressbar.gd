extends ProgressBar

func update(newValue: float):
	value = newValue
	
func barAnimation (animationPath) -> void:
	animationPath.play("progressbarUpdated")
	return
