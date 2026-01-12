extends RigidBody3D
class_name Bomb

@onready var area: Area3D = $Area3D
signal exploded(position: Vector3)


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
			PlayerData.remove_health(5)
			var kb = body.get_node("IsKnockbacked") as IsKnockbacked
			kb.start(global_position)
	await $AnimationPlayer.animation_finished
	exploded.emit()
	queue_free()
