extends PathFollow2D

@export var move_speed: float = 120.0

var direction: int = 1

func _process(delta):
	progress += move_speed * direction * delta

	if progress_ratio >= 1.0:
		direction = -1
	elif progress_ratio <= 0.0:
		direction = 1
