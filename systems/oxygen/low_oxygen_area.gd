extends Area3D

@export var difficulty: int = 1

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.determine_suffocation(true, difficulty)

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.determine_suffocation(false, difficulty)