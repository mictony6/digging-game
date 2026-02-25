extends TurretState

@export var detector: Area3D


func physics_update(_delta: float) -> void:
	var bodies: Array = detector.get_overlapping_bodies()
	if bodies.is_empty():
		return

	var data = {}
	data.target_entity = bodies[0]
	finished.emit(ALERT, data)
