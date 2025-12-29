extends StaticBody3D
class_name Rock


@export var rock_data: RockData
var current_health: float
var crack_material: ShaderMaterial
@export var break_particles: PackedScene

func _ready():
	current_health = rock_data.max_health
	#assign a random rotation for variety
	rotation_degrees.y = randi() % 360

	#random scale variation
	var scale_variation = randf_range(0.9, 1.1)
	scale = Vector3.ONE * scale_variation

	# #select a random mesh
	randomize_mesh()


func take_damage(damage: float):
	if current_health <= 0:
		current_health = 0
		destroy()
	if not rock_data.is_destructible:
		return
	current_health -= damage


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
	if current_health == rock_data.max_health:
		return
	if rock_data.is_destructible:
		var health_ratio = float(current_health) / float(rock_data.max_health) + .5
		var current_ratio = crack_material.get_shader_parameter("Edge")
		health_ratio = lerpf(current_ratio, health_ratio, 0.1)
		crack_material.set_shader_parameter("Edge", health_ratio)

func randomize_mesh():
	#select a random mesh
	for i in $MeshTypes.get_children():
		i.visible = false
	var mesh_index = randi() % $MeshTypes.get_child_count()
	$MeshTypes.get_child(mesh_index).visible = true
	crack_material = $MeshTypes.get_child(mesh_index).material_overlay
