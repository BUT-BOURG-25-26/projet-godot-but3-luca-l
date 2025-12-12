extends ProgressBar

func update(newValue: int):
	value = newValue
	
func barAnimation (animationPath) -> void:
	animationPath.play("progressbarUpdated")
	return
