extends StaticBody3D
class_name Rock

@export var rock_data: RockData
var current_health: int
signal destroyed(body: Rock)
var crack_material: ShaderMaterial

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
	crack_material = $MeshTypes.get_child(mesh_index).material_overlay

func take_damage(damage: int):
	if current_health <= 0:
		destroy()
	if not rock_data.is_destructible:
		return
	current_health -= damage


func destroy():
	QuotaManager.add_to_quota(rock_data.value)
	destroyed.emit(self)
	queue_free()

func _process(delta: float) -> void:
	#update crack shader based on health
	if current_health == rock_data.max_health:
		return
	if rock_data.is_destructible:
		var health_ratio = 1.0 - float(current_health) / float(rock_data.max_health)
		var current_ratio = crack_material.get_shader_parameter("ratio")
		health_ratio = lerpf(current_ratio, health_ratio, 0.1)
		crack_material.set_shader_parameter("ratio", health_ratio)
