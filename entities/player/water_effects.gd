extends Node

## Handles all water visual effects (splash on entry, ripple shader update).
## Connects to the existing SwimDetector — avoids dynamic Area3D creation
## which does not reliably register overlaps inside CharacterBody3D at runtime.

const SplashScene := preload("res://effects/water_splash.tscn")

var _water_mat: ShaderMaterial = null
var _area_count: int = 0
var _base_ripple_amplitude: float = 0.0
var _fade_tween: Tween = null
@onready var feet_area: Area3D = %FeetArea

func _ready() -> void:
	_water_mat = load("res://shaders/materials/water.material") as ShaderMaterial
	_base_ripple_amplitude = _water_mat.get_shader_parameter("ripple_amplitude")

	feet_area.area_entered.connect(_on_water_entered)
	feet_area.area_exited.connect(_on_water_exited)

func _process(delta: float) -> void:
	if _area_count > 0:
		var player: CharacterBody3D = get_parent()
		_water_mat.set_shader_parameter("ripple_origin", Vector2(player.global_position.x, player.global_position.z))

		var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
		var t: float = clamp(speed / player.SPRINT_SPEED, 0.0, 1.0)
		var target: float = lerp(_base_ripple_amplitude, _base_ripple_amplitude * 1.8, t)
		var current: float = _water_mat.get_shader_parameter("ripple_amplitude")
		_water_mat.set_shader_parameter("ripple_amplitude", lerp(current, target, delta * 3.0))

func _on_water_entered(area: Area3D) -> void:
	if not area.is_in_group("water_volume"):
		return
	if _area_count == 0:
		if _fade_tween:
			_fade_tween.kill()
			_fade_tween = null
		var player: CharacterBody3D = get_parent()
		var impact: float = clamp(abs(player.velocity.y) / 15.0, 0.0, 1.0)
		_water_mat.set_shader_parameter("ripple_amplitude", _base_ripple_amplitude * impact * 3.0)
		_spawn_splash()
	_area_count += 1

func _on_water_exited(area: Area3D) -> void:
	if not area.is_in_group("water_volume"):
		return
	_area_count -= 1
	if _area_count <= 0:
		_area_count = 0
		_fade_tween = create_tween()
		_fade_tween.tween_method(
			func(v: float) -> void: _water_mat.set_shader_parameter("ripple_amplitude", v),
			_base_ripple_amplitude, 0.0, 1.2
		)
		_fade_tween.tween_callback(func() -> void:
			_water_mat.set_shader_parameter("ripple_origin", Vector2(99999.0, 99999.0))
			_water_mat.set_shader_parameter("ripple_amplitude", _base_ripple_amplitude)
		)

func _spawn_splash() -> void:
	var splash: GPUParticles3D = SplashScene.instantiate()
	get_parent().get_parent().add_child(splash)
	splash.global_position = get_parent().global_position
	splash.emitting = true
	splash.finished.connect(splash.queue_free)
