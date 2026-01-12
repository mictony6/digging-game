extends Node3D
class_name IsKnockbacked


@export var entity: CharacterBody3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

func _ready() -> void:
	if !entity:
		assert(owner is CharacterBody3D, "You can only knockback physics entities")
		entity = owner


func start(source_position: Vector3):
	var direction = (entity.global_position - source_position).normalized()
	entity.velocity = direction * 10