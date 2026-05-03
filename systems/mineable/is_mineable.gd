extends Node
class_name IsMineable

@export var break_particles: PackedScene
@export var hit_sound: AudioStream
@export var destroyed_sound: AudioStream
@export var required_tool_tier: int = 1

signal destroyed

var _health: HasHealth
var _drops: HasDrops
var _last_hit_position: Vector3

func _ready() -> void:
	_health = get_parent().get_node_or_null("HasHealth")
	_drops = get_parent().get_node_or_null("HasDrops")
	if _health:
		_health.death.connect(_on_death)

func mine(damage: float, hit_position: Vector3, tool_tier: int) -> void:
	if tool_tier < required_tool_tier:
		return
	if hit_position != Vector3.ZERO:
		_last_hit_position = hit_position
	if _health:
		_health.take_damage(damage)
	else:
		_on_death()

func _on_death() -> void:
	_spawn_particles()
	_play_sound(destroyed_sound)
	var spawn_pos: Vector3 = _last_hit_position if _last_hit_position != Vector3.ZERO else get_parent().global_position
	if _drops:
		_drops.spawn_drops(spawn_pos)
	destroyed.emit()
	get_parent().queue_free()

func _spawn_particles() -> void:
	if break_particles == null:
		return
	var p: GPUParticles3D = break_particles.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = get_parent().global_position
	p.emitting = true
	p.finished.connect(p.queue_free)

func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer3D.new()
	get_tree().current_scene.add_child(player)
	player.global_position = get_parent().global_position
	player.stream = stream
	player.play()
	player.finished.connect(player.queue_free)

func destroy():
	if _health != null:
		_health.take_damage(_health.max_health)
