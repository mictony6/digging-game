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


func enter(_previous_state_path: String, _data := {}) -> void:
	player.velocity = Vector3.ZERO
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_do_vault()


func physics_update(_delta: float) -> void:
	# All logic is tween-driven from enter(); nothing to do here.
	pass


func exit() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED


# --- Internal ---

func _do_vault() -> void:
	var cam_forward := -player.head.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()

	var space := player.get_world_3d().direct_space_state
	var exclude := [player.get_rid()]

	# Ray 1: forward from eye level.  Hit = full wall → can't vault.
	var eye_pos := player.global_position + Vector3.UP * EYE_HEIGHT
	var wall_q := PhysicsRayQueryParameters3D.create(eye_pos, eye_pos + cam_forward * WALL_RAY_LENGTH)
	wall_q.collide_with_bodies = true
	wall_q.collision_mask = COLLISION_MASK
	wall_q.exclude = exclude
	if not space.intersect_ray(wall_q).is_empty():
		# It's a solid wall — bail back to Move
		finished.emit(MOVE)
		return

	# Ray 2: from above-forward downward — find ledge surface.
	var cast_from := player.global_position + cam_forward * FORWARD_PROBE + Vector3.UP * LEDGE_RAY_HEIGHT
	var ledge_q := PhysicsRayQueryParameters3D.create(cast_from, cast_from + Vector3.DOWN * LEDGE_RAY_DEPTH)
	ledge_q.collide_with_bodies = true
	ledge_q.collision_mask = COLLISION_MASK
	ledge_q.exclude = exclude
	var ledge_hit := space.intersect_ray(ledge_q)

	if ledge_hit.is_empty():
		finished.emit(MOVE)
		return

	var land_pos: Vector3 = ledge_hit.position + Vector3.UP * 0.8
	if land_pos.y <= player.global_position.y + 0.1:
		# Surface isn't higher than us
		finished.emit(MOVE)
		return

	# Clearance check: ray upward from just above landing floor to player full height
	var clearance_start: Vector3 = ledge_hit.position + Vector3.UP * 0.05
	var clearance_q := PhysicsRayQueryParameters3D.create(
		clearance_start, clearance_start + Vector3.UP * player.height)
	clearance_q.collide_with_bodies = true
	clearance_q.collision_mask = COLLISION_MASK
	clearance_q.exclude = exclude
	var clearance_hit := space.intersect_ray(clearance_q)

	var clearance: float = player.height if clearance_hit.is_empty() \
		else clearance_hit.position.y - ledge_hit.position.y

	if clearance < player.height * 0.5 - 0.05:
		# Less than half height — would get stuck, abort
		finished.emit(MOVE)
		return

	var force_crouch: bool = clearance < player.height

	var tween := player.create_tween()
	tween.tween_property(player, "global_position", land_pos, VAULT_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		player.velocity = Vector3.ZERO
		finished.emit(CROUCH if force_crouch else IDLE)
	)
