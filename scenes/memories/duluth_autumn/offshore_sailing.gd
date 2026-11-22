extends PathFollow3D
## A scenic Ensign follows a closed tack across the deep-water side of the pier.
@export_range(0.1, 3.0, 0.05) var sailing_speed := 0.85

func _process(delta: float) -> void:
	progress += sailing_speed * delta
