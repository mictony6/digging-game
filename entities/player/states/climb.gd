extends PlayerState

const CLIMB_SPEED := 2.0
const Z_OFFSET := 0.3
const LEEWAY := 75.0

var _ladder: LadderGenerator = null
var _vaulting: bool = false
var _entering: bool = false


func enter(_previous_state_path: String, _data := {}) -> void:
	_ladder = player.current_ladder
	_vaulting = false
	_entering = false
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	player.velocity = Vector3.ZERO

	if _ladder == null:
		return

	var facing_yaw := _compute_facing_yaw()
	var snap_pos := _compute_snap_position()

	_ladder.set_static_collision_enabled(false)
	_entering = true
	_play_entry_tween(facing_yaw, snap_pos)


func physics_update(_delta: float) -> void:
	if _vaulting or _entering:
		return

	if _ladder == null or player.current_ladder == null:
		_exit_to_fall()
		return

	var e_just := Input.is_action_just_pressed("pickup")
	var vert := Input.get_axis("move_backward", "move_forward")

	if e_just and vert < 0:
		_exit_to_fall()
		return

	var top_y := _ladder.get_top_position().y
	var bottom_y := _ladder.global_position.y + 1.0

	if vert < 0 and player.global_position.y <= bottom_y:
		player.velocity = Vector3.ZERO
		finished.emit(IDLE)
		return

	if e_just and vert > 0 and player.global_position.y >= top_y - 0.3:
		_vault_to_top()
		return

	player.velocity = Vector3(0.0, vert * CLIMB_SPEED, 0.0)

	if player.global_position.y >= top_y:
		player.global_position.y = top_y
		if vert >= 0:
			player.velocity.y = 0.0

	player.move_and_slide()


func exit() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	player.head.yaw_min = - INF
	player.head.yaw_max = INF
	if _ladder:
		_ladder.set_static_collision_enabled(true)
	player.current_ladder = null
	_ladder = null
	_vaulting = false
	_entering = false


# --- Helpers ---

func _compute_facing_yaw() -> float:
	var bz := _ladder.global_transform.basis.z
	var raw := rad_to_deg(atan2(bz.x, bz.z)) - player.rotation_degrees.y
	var current: float = player.head.target_rotation.y
	var diff := wrapf(raw - current, -180.0, 180.0)
	return current + diff


func _compute_snap_position() -> Vector3:
	var offset := _ladder.global_transform.basis.z * Z_OFFSET
	var top_y := _ladder.get_top_position().y
	var snap_y := top_y - 0.6 if player.global_position.y >= top_y - 0.5 \
		else player.global_position.y + 0.25
	return Vector3(
		_ladder.global_position.x + offset.x,
		snap_y,
		_ladder.global_position.z + offset.z
	)


func _play_entry_tween(facing_yaw: float, snap_pos: Vector3) -> void:
	var start_y := player.global_position.y
	var tween := player.create_tween()
	tween.tween_property(player.head, "target_rotation:y", facing_yaw, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", Vector3(snap_pos.x, start_y, snap_pos.z), 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", snap_pos, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		player.head.yaw_min = facing_yaw - LEEWAY
		player.head.yaw_max = facing_yaw + LEEWAY
		_entering = false
	)


func _vault_to_top() -> void:
	_vaulting = true
	player.velocity = Vector3.ZERO

	var forward := -_ladder.global_transform.basis.z
	var cast_from := _ladder.get_top_position() + forward * 0.2 + Vector3.UP * 0.5
	var space := player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(cast_from, cast_from + Vector3.DOWN * 2.5)
	q.collide_with_bodies = true
	q.collision_mask = 4 | 2 | 32
	var hit := space.intersect_ray(q)

	var land_pos: Vector3 = hit.position + Vector3.UP * 1.0 if not hit.is_empty() \
		else _ladder.get_top_position() + forward * 0.2

	var tween := player.create_tween()
	tween.tween_property(player, "global_position", land_pos, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_finish_vault)


func _finish_vault() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	player.velocity = Vector3.ZERO
	finished.emit(IDLE)


func _exit_to_fall() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	finished.emit(FALL)
