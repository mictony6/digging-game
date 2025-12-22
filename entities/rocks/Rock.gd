extends StaticBody3D
class_name Rock

@export var rock_data: RockData
var current_health: int
signal destroyed(body: Rock)


func _ready():
	current_health = rock_data.max_health
	#assign a random rotation for variety
	rotation_degrees.y = randi() % 360

	#random scale variation
	var scale_variation = randf_range(0.9, 1.1)
	scale = Vector3.ONE * scale_variation


	#select a random mesh
	for i in $MeshTypes.get_children():
		i.visible = false
	var mesh_index = randi() % $MeshTypes.get_child_count()
	$MeshTypes.get_child(mesh_index).visible = true


func take_damage(damage: int):
	if not rock_data.is_destructible:
		return
	current_health -= damage
	if current_health <= 0:
		destroy()

func destroy():
	QuotaManager.add_to_quota(rock_data.value)
	destroyed.emit(self)
	queue_free()
