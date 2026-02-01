extends RigidBody3D
class_name Bomb

@onready var area: Area3D = $Area3D
signal exploded(position: Vector3)
var damage = 67

@onready var flicker: OmniLight3D = $ToolFlicker


func _ready() -> void:
	get_tree().create_timer(3.0).timeout.connect(explode)
func explode():
	$AnimationPlayer.play("explode")
	$MeshInstance3D.visible = false
	var bodies_in_aoe = area.get_overlapping_bodies()
	for body in bodies_in_aoe:
		if body is Rock:
			body.destroy()
		elif body is Player:
			# raycast to player to allow hiding from explosion
			var space_state = get_world_3d().direct_space_state
	
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, body.global_position)
			query.collision_mask = 0b100111 # Layers 1, 2, 3, 6
			var result = space_state.intersect_ray(query)

			
			if result and result.collider == body:
				body.health.take_damage(damage)
				var kb = body.get_node("IsKnockbacked") as IsKnockbacked
				kb.start(global_position)
	await $AnimationPlayer.animation_finished
	exploded.emit()
	queue_free()

func _physics_process(delta: float) -> void:
	flicker.global_position = global_position
	flicker.global_position.y += .25
