extends Area3D

var is_depleting: bool = false

func _process(delta: float) -> void:
	if is_depleting and PlayerData.has_oxygen():
		PlayerData.remove_oxygen(PlayerData.depletion_rate * delta)


func _on_body_entered(body: Node3D) -> void:
	is_depleting = true

func _on_body_exited(body: Node3D) -> void:
	is_depleting = false