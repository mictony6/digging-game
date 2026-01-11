extends Node3D
class_name ToolManager


@export var tool: Tool
@export var tool_raycast: RayCast3D
@export var tool_aoe_mesh: MeshInstance3D
@export var tool_area3d: Area3D
@export var hit_particles: PackedScene
@export var break_particles: PackedScene

var particle_instances: Array[GPUParticles3D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tool_area3d.body_entered.connect(_on_body_entered)
	tool_area3d.body_exited.connect(_on_body_exited)
	tool_raycast.enabled = false
	
var bodies_in_aoe: Array[Rock] = []

@export var tool_max_cooldown: float = 0.75
var tool_current_cooldown: float = 0.0

var _pressing: bool = false
func _process(_delta: float) -> void:
	_pressing = Input.is_action_pressed("action")
func _physics_process(delta: float) -> void:
	if _pressing:
		tool_raycast.force_raycast_update()
	tool_current_cooldown = max(tool_current_cooldown - delta, 0.0)
	if _pressing and tool_raycast.is_colliding() and tool_raycast.get_collider() != null:
		# tool_aoe_mesh.visible = true
		var collision_point = tool_raycast.get_collision_point()

		# tool_aoe_mesh.global_position = collision_point
		tool_area3d.global_position = tool_raycast.get_collider().global_position
		tool_area3d.monitoring = true

		if tool_current_cooldown <= 0.0:
			for body in bodies_in_aoe:
				if body.rock_data.tier <= tool.tool_data.tier:
					if body == tool_raycast.get_collider():
						body.take_damage(tool.tool_data.strength)
					else:
						body.take_damage(tool.tool_data.strength / 4.0) # quarter damage to neighboring rocks
					tool_current_cooldown = tool_max_cooldown
			#spawn hit particles
			var particles_instance: GPUParticles3D = hit_particles.instantiate()
			get_tree().current_scene.add_child(particles_instance)
			particle_instances.append(particles_instance)
			particles_instance.global_position = collision_point
			particles_instance.emitting = true
			particles_instance.finished.connect(particles_instance.queue_free)
			
			if particle_instances.size() > 5:
				var oldest_particle = particle_instances.pop_front()
				if oldest_particle != null:
					oldest_particle.queue_free()

			#align particles to surface normal
			var collision_normal = tool_raycast.get_collision_normal()
			particles_instance.look_at(particles_instance.global_position + collision_normal, Vector3.UP)


func _on_body_entered(body: Node) -> void:
	if body is Rock and body not in bodies_in_aoe:
		bodies_in_aoe.append(body)
		# body.destroyed.connect(_on_rock_destroyed)

func _on_body_exited(body: Node) -> void:
	if body is Rock and body in bodies_in_aoe:
		bodies_in_aoe.erase(body)
		# body.destroyed.disconnect(_on_rock_destroyed)

# func _on_rock_destroyed(body: Rock) -> void:
# 	#spawn break particles
# 	var particles_instance: GPUParticles3D = break_particles.instantiate()
# 	get_tree().current_scene.add_child(particles_instance)
# 	particle_instances.append(particles_instance)
# 	particles_instance.global_position = body.global_position
# 	particles_instance.emitting = true
# 	particles_instance.finished.connect(particles_instance.queue_free)
# 	if body in bodies_in_aoe:
# 		bodies_in_aoe.erase(body)
# 		body.destroyed.disconnect(_on_rock_destroyed)
