extends TurretState
var target_entity: Node3D = null
var lock_on_angle: float = 5.0
var time_in_view: float = 0.0
var lock_on_time: float = 1.0
@export var detector: Area3D


func enter(_previous_state_path: String, data := {}) -> void:
	time_in_view = 0.0

func physics_update(delta: float) -> void:
	var bodies: Array = detector.get_overlapping_bodies()
	if bodies.is_empty():
		finished.emit(IDLE)
		return
	target_entity = bodies[0]

	look_at_target(target_entity, delta)
	if check_lock_on(delta):
		finished.emit(LOCKED_IN)


func look_at_target(entity: Node3D, delta: float):
	var target_pos = entity.global_position
	target_pos.y = head.global_position.y
	
	var target_transform = head.global_transform.looking_at(target_pos, Vector3.UP)
	head.global_transform.basis = head.global_transform.basis.slerp(target_transform.basis, delta * 10.0)


func check_lock_on(delta: float) -> bool:
	var to_target = (target_entity.global_position - %BombSpawnLoc.global_position).normalized()
	to_target.y = 0
	to_target = to_target.normalized()
	
	var forward = - head.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var angle = rad_to_deg(acos(clamp(forward.dot(to_target), -1.0, 1.0)))
	
	if angle < lock_on_angle and has_line_of_sight():
		time_in_view += delta
		if time_in_view >= lock_on_time:
			return true
	else:
		time_in_view = 0.0
	return false

func has_line_of_sight() -> bool:
	var space_state = head.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		%BombSpawnLoc.global_position,
		target_entity.global_position
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 0b100110
	query.exclude = [head.get_rid()]
	var result = space_state.intersect_ray(query)
	return result.is_empty() # true = nothing blocking
