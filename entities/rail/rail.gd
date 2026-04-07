@tool
extends Path3D
class_name Rail

@onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D
@onready var support_multimesh_instance: MultiMeshInstance3D = $SupportMesh
@onready var rail_mesh_instance: MeshInstance3D = $RailMesh

@export var mesh: Mesh
@export_tool_button("Build") var build = func():
	build_multimesh()
	build_rails()
	build_supports()

@export var spacing: float = 1.0:
	set(value):
		spacing = value
		build_multimesh()
@export var tie_y_offset: float = 0.0:
	set(value):
		tie_y_offset = value
		build_multimesh()
@export var tie_rotation_offset: Vector3 = Vector3(90, 0, 0):
	set(value):
		tie_rotation_offset = value
		build_multimesh()

# Support beam properties
@export_group("Support Beams")
@export var support_mesh: Mesh
@export var support_height_threshold: float = 0.25:
	set(value):
		support_height_threshold = value
		build_supports()
@export var support_spacing: float = 1.0:
	set(value):
		support_spacing = value
		build_supports()
@export var support_ray_length: float = 50.0
@export var support_mesh_height: float = 1.0:
	set(value):
		support_mesh_height = value
		build_supports()

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
@export var rail_y_offset: float = 0.0:
	set(value):
		rail_y_offset = value
		build_rails()


func _ready() -> void:
	curve.changed.connect(_on_curve_changed)
	build_multimesh()
	build_rails()
	build_supports()


func _on_curve_changed() -> void:
	build_multimesh()
	build_rails()
	build_supports()


func _ensure_static_body(body_name: String) -> StaticBody3D:
	var existing = get_node_or_null(body_name)
	if existing is StaticBody3D:
		for child in existing.get_children():
			child.queue_free()
		return existing
	if existing:
		existing.queue_free()
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = 4
	body.collision_mask = 0
	add_child(body)
	return body


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
		var rot_offset := Basis.from_euler(Vector3(deg_to_rad(tie_rotation_offset.x), deg_to_rad(tie_rotation_offset.y), deg_to_rad(tie_rotation_offset.z)))
		var xform := Transform3D(tie_basis * rot_offset, pos + tie_basis.y * tie_y_offset)
		mm.set_instance_transform(i, xform)

	multimesh_instance.multimesh = mm

	if not Engine.is_editor_hint() and mesh:
		var body := _ensure_static_body("TieCollision")
		var aabb := mesh.get_aabb()
		var box := BoxShape3D.new()
		box.size = aabb.size
		var center_offset := aabb.get_center()
		for i in count:
			var offset: float = step * i
			var pos := curve.sample_baked(offset)
			var tangent: Vector3 = (curve.sample_baked(minf(offset + 0.01, total_length)) - curve.sample_baked(maxf(offset - 0.01, 0.0))).normalized()
			var up := Vector3.UP
			if abs(tangent.dot(up)) > 0.99:
				up = Vector3.FORWARD
			var tie_basis := Basis.looking_at(tangent, up)
			var rot_offset := Basis.from_euler(Vector3(deg_to_rad(tie_rotation_offset.x), deg_to_rad(tie_rotation_offset.y), deg_to_rad(tie_rotation_offset.z)))
			var xform := Transform3D(tie_basis * rot_offset, pos + tie_basis.y * tie_y_offset + (tie_basis * rot_offset) * center_offset)
			var col := CollisionShape3D.new()
			col.shape = box
			col.transform = xform
			body.add_child(col)


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

	if not Engine.is_editor_hint():
		var body := _ensure_static_body("RailCollision")
		var col := CollisionShape3D.new()
		col.shape = rail_mesh_instance.mesh.create_trimesh_shape()
		body.add_child(col)


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

	# Precompute U coords along the perimeter so each face is proportional (no cross-section stretch)
	var perimeter := 0.0
	for j in profile_size:
		perimeter += profile[j].distance_to(profile[(j + 1) % profile_size])
	var u_coords := PackedFloat32Array()
	u_coords.append(0.0)
	var dist := 0.0
	for j in profile_size:
		dist += profile[j].distance_to(profile[(j + 1) % profile_size])
		u_coords.append(dist / perimeter)

	var prev_ring: Array[Vector3] = []
	var prev_v := 0.0

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
		var center := pos + rail_basis.x * x_offset + rail_basis.y * rail_y_offset

		var ring: Array[Vector3] = []
		for p in profile:
			ring.append(center + rail_basis.x * p.x + rail_basis.y * p.y)

		if prev_ring.size() > 0:
			for j in profile_size:
				var j_next := (j + 1) % profile_size
				var u0 := u_coords[j]
				var u1 := u_coords[j + 1]

				st.set_smooth_group(j)
				st.set_uv(Vector2(u0, prev_v)); st.add_vertex(prev_ring[j])
				st.set_uv(Vector2(u1, prev_v)); st.add_vertex(prev_ring[j_next])
				st.set_uv(Vector2(u0, offset)); st.add_vertex(ring[j])

				st.set_uv(Vector2(u1, prev_v)); st.add_vertex(prev_ring[j_next])
				st.set_uv(Vector2(u1, offset)); st.add_vertex(ring[j_next])
				st.set_uv(Vector2(u0, offset)); st.add_vertex(ring[j])

		prev_ring = ring
		prev_v = offset


# --- Support beams ---

func build_supports() -> void:
	if not support_multimesh_instance or not support_mesh or spacing <= 0:
		return

	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return

	var total_length := curve.get_baked_length()
	if total_length == 0.0:
		return

	var count := int(total_length / support_spacing) + 1
	var step: float = total_length / max(count - 1, 1)

	var beam_xforms: Array[Transform3D] = []

	for i in count:
		var offset := step * i
		var local_pos := curve.sample_baked(offset)
		var world_pos := to_global(local_pos)

		var query := PhysicsRayQueryParameters3D.create(
			world_pos, world_pos + Vector3.DOWN * support_ray_length)
		query.collision_mask = 4 + 32
		var hit := space_state.intersect_ray(query)
		if not hit:
			continue

		var height: float = world_pos.y - hit.position.y
		if height <= support_height_threshold:
			continue

		var tangent := (curve.sample_baked(minf(offset + 0.01, total_length)) - curve.sample_baked(maxf(offset - 0.01, 0.0))).normalized()
		var yaw := atan2(tangent.x, tangent.z)
		var rot_basis := Basis(Vector3.UP, yaw)
		var rail_local := to_local(world_pos)
		var full_count := floori(height / support_mesh_height)
		for s in full_count:
			var beam_pos := rail_local - Vector3.UP * (support_mesh_height * (s + 0.5))
			beam_xforms.append(Transform3D(rot_basis, beam_pos))
		var remainder := height - full_count * support_mesh_height
		if remainder > 0.001:
			var scaled_basis := Basis(Vector3.UP, yaw).scaled(Vector3(1.0, remainder / support_mesh_height, 1.0))
			var beam_pos := rail_local - Vector3.UP * (full_count * support_mesh_height + remainder * 0.5)
			beam_xforms.append(Transform3D(scaled_basis, beam_pos))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = beam_xforms.size()
	mm.mesh = support_mesh
	for i in beam_xforms.size():
		mm.set_instance_transform(i, beam_xforms[i])

	support_multimesh_instance.multimesh = mm

	if not Engine.is_editor_hint():
		var body := _ensure_static_body("SupportCollision")
		var aabb := support_mesh.get_aabb()
		var base_box := BoxShape3D.new()
		base_box.size = aabb.size
		var center_offset := aabb.get_center()
		for xform in beam_xforms:
			var col := CollisionShape3D.new()
			# For scaled beams (remainder segments) the basis includes scale — extract it
			if xform.basis.determinant() != 1.0:
				var scaled_box := BoxShape3D.new()
				scaled_box.size = aabb.size * xform.basis.get_scale()
				col.shape = scaled_box
				col.transform = Transform3D(xform.basis.orthonormalized(), xform.origin + xform.basis * center_offset)
			else:
				col.shape = base_box
				col.transform = Transform3D(xform.basis, xform.origin + xform.basis * center_offset)
			body.add_child(col)
