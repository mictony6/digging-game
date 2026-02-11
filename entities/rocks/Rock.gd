extends StaticBody3D
class_name Rock


@export var rock_data: RockData
@export var break_particles: PackedScene
@export var mesh: MeshInstance3D
@onready var health: HasHealth = $HasHealth

func _ready():
	health.max_health = rock_data.max_health
	health.current_health = rock_data.max_health
	health.death.connect(destroy)
	#assign a random rotation for variety
	rotation_degrees.y = randi() % 360

	#random scale variation
	var scale_variation = randf_range(0.9, 1.1)
	scale = Vector3.ONE * scale_variation

	mesh.set_instance_shader_parameter("damage", 0.0)


func take_damage(damage: float):
	if rock_data.is_destructible:
		health.take_damage(damage)


func destroy():
	QuotaManager.add_to_quota(rock_data.value)
	var particles_instance: GPUParticles3D = break_particles.instantiate()
	get_tree().current_scene.add_child(particles_instance)
	particles_instance.global_position = global_position
	particles_instance.emitting = true
	particles_instance.finished.connect(particles_instance.queue_free)
	queue_free()

func _process(delta: float) -> void:
	#update crack shader based on health
	if health.is_max_health():
		return
	if rock_data.is_destructible:
		var health_ratio = 1.0 - float(health.current_health) / float(health.max_health)
		var current_ratio = mesh.get_instance_shader_parameter("damage")
		health_ratio = lerpf(current_ratio, health_ratio, 0.1)
		mesh.set_instance_shader_parameter("damage", health_ratio)
