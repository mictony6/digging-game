@tool
extends Path3D
class_name Rail

@onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D
@onready var rail_mesh_instance: MeshInstance3D = $RailMesh

@export var mesh: Mesh
@export_tool_button("Build") var build = func():
	build_multimesh()
	build_rails()

@export var spacing: float = 1.0:
	set(value):
		spacing = value
		build_multimesh()
@export var tie_y_offset: float = 0.0:
	set(value):
		tie_y_offset = value
		build_multimesh()

# Rail bar properties
@export_group("Rail Bars")
@export var rail_gauge: float = 0.8:
	set(value):
		rail_gauge = value
		build_rails()
@export var rail_width: float = 0.05:
	set(value):
		rail_width = value
		build_rails()
@export var rail_height: float = 0.08:
	set(value):
		rail_height = value
		build_rails()
@export var rail_segments: int = 64:
	set(value):
		rail_segments = value
		build_rails()


func _ready() -> void:
	curve.changed.connect(_on_curve_changed)
	build_multimesh()
	build_rails()


func _on_curve_changed() -> void:
	build_multimesh()
	build_rails()


# --- Ties (cross pieces) ---

func build_multimesh() -> void:
	if not multimesh_instance or not mesh or spacing <= 0:
		return

	var total_length := curve.get_baked_length()
	var count := int(total_length / spacing) + 1
	var step: float = total_length / max(count - 1, 1)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = mesh

	for i in count:
		var offset: float = step * i
		var pos := curve.sample_baked(offset)
		var tangent: Vector3 = (curve.sample_baked(minf(offset + 0.01, total_length)) - curve.sample_baked(maxf(offset - 0.01, 0.0))).normalized()
		var up := Vector3.UP
		if abs(tangent.dot(up)) > 0.99:
			up = Vector3.FORWARD
		var tie_basis := Basis.looking_at(tangent, up)
		var xform := Transform3D(tie_basis, pos + tie_basis.y * tie_y_offset)
		mm.set_instance_transform(i, xform)

	multimesh_instance.multimesh = mm


# --- Rail bars (extruded along path) ---

func build_rails() -> void:
	if not rail_mesh_instance or curve.get_baked_length() == 0.0:
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_extrude_rail(st, -rail_gauge * 0.5)
	_extrude_rail(st, rail_gauge * 0.5)

	st.generate_normals()
	rail_mesh_instance.mesh = st.commit()


func _extrude_rail(st: SurfaceTool, x_offset: float) -> void:
	var total_length := curve.get_baked_length()
	var step: float = total_length / rail_segments

	# Rectangle cross-section: bottom-left, bottom-right, top-right, top-left
	var hw := rail_width * 0.5
	var profile := PackedVector2Array([
		Vector2(-hw, 0.0),
		Vector2(hw, 0.0),
		Vector2(hw, rail_height),
		Vector2(-hw, rail_height),
	])
	var profile_size := profile.size()

	var prev_ring: Array[Vector3] = []

	for i in rail_segments + 1:
		var offset: float = step * i
		var pos := curve.sample_baked(offset)

		var tangent: Vector3 = (
			curve.sample_baked(minf(offset + 0.01, total_length)) -
			curve.sample_baked(maxf(offset - 0.01, 0.0))
		).normalized()

		var up := Vector3.UP
		if abs(tangent.dot(up)) > 0.99:
			up = Vector3.FORWARD

		var rail_basis := Basis.looking_at(tangent, up)
		var center := pos + rail_basis.x * x_offset

		var ring: Array[Vector3] = []
		for p in profile:
			ring.append(center + rail_basis.x * p.x + rail_basis.y * p.y)

		if prev_ring.size() > 0:
			for j in profile_size:
				var j_next := (j + 1) % profile_size
				st.add_vertex(prev_ring[j])
				st.add_vertex(prev_ring[j_next])
				st.add_vertex(ring[j])

				st.add_vertex(prev_ring[j_next])
				st.add_vertex(ring[j_next])
				st.add_vertex(ring[j])

		prev_ring = ring
