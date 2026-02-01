@tool
extends StaticBody3D
class_name Rock


@export var rock_data: RockData
var crack_material: ShaderMaterial
@export var break_particles: PackedScene

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

	var shapes: Array[CollisionShape3D] = []
	for node in get_children():
		if node is CollisionShape3D:
			node.disabled = true
			shapes.append(node)

	
	# #select a random mesh
	var index: int = randomize_mesh()
	var shape: CollisionShape3D = shapes[index]
	shape.disabled = false


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
	if Engine.is_editor_hint():
		return
	#update crack shader based on health
	if health.is_max_health():
		return
	if rock_data.is_destructible:
		var health_ratio = float(health.current_health) / float(health.max_health) + .5
		var current_ratio = crack_material.get_shader_parameter("Edge")
		health_ratio = lerpf(current_ratio, health_ratio, 0.1)
		crack_material.set_shader_parameter("Edge", health_ratio)

func randomize_mesh():
	#select a random mesh
	var mesh: MeshInstance3D
	var mesh_index = randi() % $MeshTypes.get_child_count()
	for i in $MeshTypes.get_children():
		i.visible = false
	mesh = $MeshTypes.get_child(mesh_index)
	mesh.visible = true
	crack_material = mesh.material_overlay
	return mesh_index
