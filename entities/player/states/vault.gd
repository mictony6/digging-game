extends PlayerState

# How far forward (flat) to probe for a ledge surface
const FORWARD_PROBE := 0.6
# How high above the player to start the downward ledge ray (~1m max vault height)
const LEDGE_RAY_HEIGHT := 1.2
# How far down to sweep the ledge ray
const LEDGE_RAY_DEPTH := 1.5
# Forward wall-check ray length (eye-level)
const WALL_RAY_LENGTH := 1.0
# Height offset for eye-level ray origin
const EYE_HEIGHT := 1.3
# Vault tween duration
const VAULT_DURATION := 0.5
# Collision mask matching terrain / static bodies
const COLLISION_MASK := 4 | 2 | 32

var _fallback_state: String = MOVE


func enter(previous_state_path: String, data := {}) -> void:
	_fallback_state = previous_state_path # "Swim", "Move", "Sprint", etc.
	player.velocity = Vector3.ZERO
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_do_vault(data.get("wall_normal", Vector3.ZERO))


func physics_update(_delta: float) -> void:
	# All logic is tween-driven from enter(); nothing to do here.
	pass


func exit() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED


func _do_vault(wall_normal: Vector3) -> void:
	var cam_forward := _vault_forward(wall_normal)

	if _is_wall_blocking(cam_forward):
		finished.emit(_fallback_state)
		return

	var ledge_hit := _find_ledge(cam_forward)
	if ledge_hit.is_empty():
		finished.emit(_fallback_state)
		return

	var land_pos: Vector3 = ledge_hit.position + Vector3.UP * 1.0
	if land_pos.y <= player.global_position.y + 0.1:
		# Surface isn't higher than us
		finished.emit(_fallback_state)
		return

	var clearance := _measure_clearance(ledge_hit.position)
	if clearance < player.height * 0.5 - 0.05:
		# Less than half height — would get stuck, abort
		finished.emit(_fallback_state)
		return

	_tween_to_ledge(land_pos, clearance < player.height)


# Probe direction: straight into the wall when we know its normal, so vaulting
# works at shallow approach angles; camera forward otherwise (e.g. from Swim).
func _vault_forward(wall_normal: Vector3) -> Vector3:
	var into_wall := -wall_normal
	into_wall.y = 0.0
	if into_wall.length() > 0.1:
		return into_wall.normalized()
	return _flat_camera_forward()


func _flat_camera_forward() -> Vector3:
	var cam_forward := -player.head.global_transform.basis.z
	cam_forward.y = 0.0
	return cam_forward.normalized()


func _raycast(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collision_mask = COLLISION_MASK
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(query)


# Forward from eye level.  Hit = full wall → can't vault.
func _is_wall_blocking(cam_forward: Vector3) -> bool:
	var eye_pos := player.global_position + Vector3.UP * EYE_HEIGHT
	return not _raycast(eye_pos, eye_pos + cam_forward * WALL_RAY_LENGTH).is_empty()


# From above-forward downward — find ledge surface.
func _find_ledge(cam_forward: Vector3) -> Dictionary:
	var cast_from := player.global_position + cam_forward * FORWARD_PROBE + Vector3.UP * LEDGE_RAY_HEIGHT
	return _raycast(cast_from, cast_from + Vector3.DOWN * LEDGE_RAY_DEPTH)


# Ray upward from just above landing floor to player full height
func _measure_clearance(ledge_pos: Vector3) -> float:
	var clearance_start := ledge_pos + Vector3.UP * 0.05
	var clearance_hit := _raycast(clearance_start, clearance_start + Vector3.UP * player.height)
	if clearance_hit.is_empty():
		return player.height
	return clearance_hit.position.y - ledge_pos.y


func _tween_to_ledge(land_pos: Vector3, force_crouch: bool) -> void:
	var tween := player.create_tween()
	tween.tween_property(player, "global_position", land_pos, VAULT_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		player.velocity = Vector3.ZERO
		finished.emit(CROUCH if force_crouch else IDLE)
	)
