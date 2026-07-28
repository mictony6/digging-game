extends PlayerState

const SWIM_SPEED := 1.8

# Water entry is detected via an Area3D signal, which only resolves once per
# physics tick. Movement now runs every render frame, so a fast fall can
# punch several frames deeper than the surface before the signal fires.
# Rather than leaving the player stuck too deep, settle back up to a normal
# entry depth at a bounded speed once we notice the overshoot.
const EXPECTED_ENTRY_DEPTH := 0.2
const MAX_ENTRY_CORRECTION := 3.0
const ENTRY_CORRECTION_SPEED := 6.0

const TrailScene := preload("res://effects/water_trail.tscn")

var _trail: GPUParticles3D = null
var _entry_correction_target_y: float = - INF

func enter(_previous_state_path: String, _data := {}) -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	# Bleed off downward momentum like water resistance, then give a gentle
	# upward drift so the player slowly floats back to the surface.
	if player.velocity.y < -1.0:
		player.velocity.y = 0.4
	else:
		player.velocity.y = 0.0

	var target_y := player.water_surface_y - EXPECTED_ENTRY_DEPTH
	var overshoot := clampf(target_y - player.global_position.y, 0.0, MAX_ENTRY_CORRECTION)
	_entry_correction_target_y = target_y if overshoot > 0.0 else -INF

	# Continuous trail parented to player so it follows movement
	_trail = TrailScene.instantiate()
	player.add_child(_trail)
	_trail.position = Vector3(0, 0.2, 0)
	_trail.emitting = true

func update(delta: float) -> void:
	#move player y to expected level because update tends to overshoot after the physics detects player is in water
	if _entry_correction_target_y > -INF:
		player.global_position.y = move_toward(player.global_position.y, _entry_correction_target_y, ENTRY_CORRECTION_SPEED * delta)
		if is_equal_approx(player.global_position.y, _entry_correction_target_y):
			_entry_correction_target_y = - INF

	player.velocity.y = move_toward(player.velocity.y, 0.0, 1.0 * delta)

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * SWIM_SPEED, 10.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * SWIM_SPEED, 10.0 * delta)

	player.move_and_slide()

	if is_instance_valid(_trail):
		var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.1
		_trail.emitting = moving

	if not player.in_water:
		finished.emit(IDLE)
		return

	# Climb out: Space + W while near a ledge
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_forward"):
		var data := {}
		if player.is_on_wall():
			data["wall_normal"] = player.get_wall_normal()
		finished.emit(VAULT, data)

func exit() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

	if is_instance_valid(_trail):
		_trail.emitting = false
		var lifetime := _trail.lifetime
		player.get_tree().create_timer(lifetime).timeout.connect(_trail.queue_free, CONNECT_ONE_SHOT)
	_trail = null
