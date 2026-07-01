extends ColorRect


@onready var head: Node3D
@onready var viewport := get_viewport()

func _ready() -> void:
	head = get_tree().get_nodes_in_group("Head")[0]

func _process(_delta: float) -> void:
	var mat := material as ShaderMaterial
	var vp_size := viewport.get_visible_rect().size
	var cam := viewport.get_camera_3d()
	mat.set_shader_parameter("camera_basis", head.global_basis)
	mat.set_shader_parameter("fov_tan", tan(deg_to_rad(cam.fov * 0.5)))
	mat.set_shader_parameter("aspect_ratio", vp_size.x / vp_size.y)
