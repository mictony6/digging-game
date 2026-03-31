extends StaticBody3D
class_name Rock


@export var rock_data: RockData
@export var break_particles: PackedScene
@export var mesh: MeshInstance3D
@export var drops: Array[RockDrop] = []
@export var pickup_scene: PackedScene
@onready var health: HasHealth = $HasHealth
var _last_hit_position: Vector3

func _ready():
	health.max_health = rock_data.max_health
	health.current_health = rock_data.max_health
	health.death.connect(destroy)
	# #assign a random rotation for variety
	# rotation_degrees.y = randi() % 360

	# #random scale variation
	# var scale_variation = randf_range(0.9, 1.1)
	# scale = Vector3.ONE * scale_variation

	mesh.set_instance_shader_parameter("damage", 0.0)
	set_process(false)


func take_damage(damage: float, hit_position: Vector3 = Vector3.ZERO):
	if rock_data.is_destructible:
		if hit_position != Vector3.ZERO:
			_last_hit_position = hit_position
		health.take_damage(damage)
		set_process(true)


func destroy():
	QuotaManager.add_to_quota(rock_data.value)
	var particles_instance: GPUParticles3D = break_particles.instantiate()
	get_tree().current_scene.add_child(particles_instance)
	particles_instance.global_position = global_position
	particles_instance.emitting = true
	particles_instance.finished.connect(particles_instance.queue_free)
	_spawn_drops()
	queue_free()

func _spawn_drops() -> void:
	if pickup_scene == null or drops.is_empty():
		return
	for drop: RockDrop in drops:
		if drop.item == null:
			continue
		var qty := randi_range(drop.min_qty, drop.max_qty)
		if qty <= 0:
			continue
		# var pickup = pickup_scene.instantiate()
		# pickup.item_data = drop.item
		# pickup.quantity = qty

		for i in range(qty):
			var pickup: PickupItem = pickup_scene.instantiate()
			pickup.item_data = drop.item
			pickup.quantity = 1

			# Set position before add_child so _ready() captures the correct _start_y for bobbing
			var spawn_base := _last_hit_position if _last_hit_position != Vector3.ZERO else global_position
			var offset := Vector3(randf_range(-0.2, 0.2), randf_range(0.1, 0.3), randf_range(-0.2, 0.2))
			pickup.position = spawn_base + offset
			get_tree().current_scene.add_child(pickup)

func _process(delta: float) -> void:
	#update crack shader based on health
	if health.is_max_health():
		return
	if rock_data.is_destructible:
		var health_ratio = 1.0 - float(health.current_health) / float(health.max_health)
		var current_ratio = mesh.get_instance_shader_parameter("damage")
		var speed = 100.0
		health_ratio = lerpf(current_ratio, health_ratio, 1.0 - exp(-speed * delta))
		mesh.set_instance_shader_parameter("damage", min(health_ratio, 0.9))
