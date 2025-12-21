@tool
extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.mesh = create_beam_mesh()


func create_beam_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()

	# Two planes rotated 90 degrees
	_add_plane(mesh, 0)
	_add_plane(mesh, PI * 0.5)

	return mesh

func _add_plane(mesh: ArrayMesh, rot_y: float):
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var basis := Basis(Vector3.UP, rot_y)

	var size := 0.5

	var v = [
		basis * Vector3(-size, 0, 0),
		basis * Vector3(size, 0, 0),
		basis * Vector3(size, 1, 0),
		basis * Vector3(-size, 1, 0)
	]

	var uv = [
		Vector2(0, 1),
		Vector2(1, 1),
		Vector2(1, 0),
		Vector2(0, 0)
	]

	st.set_uv(uv[0]); st.add_vertex(v[0])
	st.set_uv(uv[1]); st.add_vertex(v[1])
	st.set_uv(uv[2]); st.add_vertex(v[2])

	st.set_uv(uv[2]); st.add_vertex(v[2])
	st.set_uv(uv[3]); st.add_vertex(v[3])
	st.set_uv(uv[0]); st.add_vertex(v[0])

	st.generate_normals()
	st.commit(mesh)