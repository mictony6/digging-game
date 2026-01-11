extends Area3D

@export var difficulty: int = 1
var is_depleting: bool = false

func _process(delta: float) -> void:
	if is_depleting and PlayerData.has_oxygen():
		PlayerData.remove_oxygen(PlayerData.depletion_rate * difficulty * delta)
	else:
		PlayerData.add_oxygen(PlayerData.depletion_rate * difficulty * delta * .1)


func _on_body_entered(_body: Node3D) -> void:
	is_depleting = true

func _on_body_exited(_body: Node3D) -> void:
	is_depleting = false