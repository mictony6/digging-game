extends PlayerState

const SWIM_SPEED := 1.8

const SplashScene := preload("res://effects/water_splash.tscn")
const TrailScene := preload("res://effects/water_trail.tscn")

var _trail: GPUParticles3D = null
var _water_mat: ShaderMaterial = null

func enter(_previous_state_path: String, _data := {}) -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	player.velocity.y = 0.0

	_water_mat = load("res://shaders/materials/water.material") as ShaderMaterial

	# One-shot splash at water entry position
	var splash: GPUParticles3D = SplashScene.instantiate()
	player.get_parent().add_child(splash)
	splash.global_position = player.global_position
	splash.emitting = true
	splash.finished.connect(splash.queue_free)

	# Continuous trail parented to player so it follows movement
	_trail = TrailScene.instantiate()
	player.add_child(_trail)
	_trail.position = Vector3(0, 0.2, 0)
	_trail.emitting = true

func physics_update(delta: float) -> void:
	player.velocity.y = 0.0

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * SWIM_SPEED, 10.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * SWIM_SPEED, 10.0 * delta)

	player.move_and_slide()

	if is_instance_valid(_trail):
		var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.1
		_trail.emitting = moving

	if _water_mat:
		_water_mat.set_shader_parameter("ripple_origin",
			Vector2(player.global_position.x, player.global_position.z))

	if not player.in_water:
		finished.emit(IDLE)

func exit() -> void:
	player.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

	if is_instance_valid(_trail):
		_trail.emitting = false
		var lifetime := _trail.lifetime
		player.get_tree().create_timer(lifetime).timeout.connect(_trail.queue_free, CONNECT_ONE_SHOT)
	_trail = null

	if _water_mat:
		_water_mat.set_shader_parameter("ripple_origin", Vector2(99999.0, 99999.0))
	_water_mat = null
