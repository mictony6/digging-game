extends StaticBody3D
class_name Rock

@export var rock_data: RockData
@export var mesh: MeshInstance3D
@onready var health: HasHealth = $HasHealth

func _ready():
	health.max_health = rock_data.max_health
	health.current_health = rock_data.max_health
	health.death.connect(func(): QuotaManager.add_to_quota(rock_data.value))
	mesh.set_instance_shader_parameter("damage", 0.0)
	set_process(false)
	health.health_changed.connect(func(_c, _m): set_process(true))

func _process(delta: float) -> void:
	if health.is_max_health():
		set_process(false)
		return
	if rock_data.is_destructible:
		var health_ratio := 1.0 - float(health.current_health) / float(health.max_health)
		var current_ratio: float = mesh.get_instance_shader_parameter("damage")
		health_ratio = lerpf(current_ratio, health_ratio, 1.0 - exp(-100.0 * delta))
		mesh.set_instance_shader_parameter("damage", min(health_ratio, 0.9))

func get_drops() -> Array[DropData]:
	var drops: HasDrops = get_node_or_null("HasDrops")
	if drops != null:
		return drops.drops
	return []
