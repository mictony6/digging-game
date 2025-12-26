extends MeshInstance3D
class_name Trajectory

var points: Array = []

func _ready():
    mesh = ImmediateMesh.new()

func _process(_delta):
    if points.size() < 2:
        return
    
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    
    for point in points:
        mesh.surface_add_vertex(to_local(point))
    
    mesh.surface_end()
	