extends Node3D
class_name TorchManager

@export var torch_scene: PackedScene
var last_torch: StaticBody3D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("torch"):
		var result = raycast_forward()
		if result and result.position and result.normal:
			attempt_place_torch(result.position, result.normal)


func raycast_forward():
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + (-global_transform.basis.z) * 1.5)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 4
	var result = space_state.intersect_ray(query)
	return result

func attempt_place_torch(pos: Vector3, normal: Vector3):
	assert(pos != null, "Attempting to place torch at null")
	var torch: StaticBody3D = torch_scene.instantiate()
	get_tree().root.add_child(torch)
	torch.global_position = pos
	var target_pos = torch.global_transform.origin + normal
	torch.look_at(target_pos, Vector3.UP)
