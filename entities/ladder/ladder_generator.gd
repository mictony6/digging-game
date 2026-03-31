@tool
extends Node3D
class_name LadderGenerator

const IsSelectableScene := preload("res://systems/interaction/is_selectable.tscn")

@onready var rung_multimesh: MultiMeshInstance3D = $RungMultimesh
@onready var stile_left: MeshInstance3D = $StileMeshLeft
@onready var stile_right: MeshInstance3D = $StileMeshRight
@export var rung_mesh: Mesh
@export var stile_thickness: float = 0.06:
	set(value):
		stile_thickness = value
		generate_rungs()

var _climb_area: Area3D = null
var _climb_shape: BoxShape3D = null
var _static_body: StaticBody3D = null
var _top_selectable: IsSelectable = null

@export_range(0.0, 50, 0.1) var height: float = 2.0:
	set(value):
		height = value
		generate_rungs()
@export var spacing: float = 0.5:
	set(value):
		spacing = value
		generate_rungs()


func _ready() -> void:
	rung_multimesh.multimesh = MultiMesh.new()
	rung_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D

	if not Engine.is_editor_hint():
		# Climb trigger area (ladder body)
		_climb_shape = BoxShape3D.new()
		var col := CollisionShape3D.new()
		col.shape = _climb_shape
		_climb_area = Area3D.new()
		_climb_area.collision_layer = 256 # layer 9 — ladders
		_climb_area.collision_mask = 0
		_climb_area.add_to_group("ladder")
		_climb_area.add_child(col)
		add_child(_climb_area)

		# Static collision — same box shape as the climb area
		var static_col := CollisionShape3D.new()
		static_col.shape = _climb_shape
		_static_body = StaticBody3D.new()
		_static_body.add_child(static_col)
		add_child(_static_body)


	generate_rungs()


func _make_selectable(label: String, local_pos: Vector3, shape_size: Vector3) -> IsSelectable:
	var s: IsSelectable = IsSelectableScene.instantiate()
	s.interaction_name = label
	s.secondary_interaction_name = label
	s.collision_layer = 16
	s.position = local_pos
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = shape_size
	col.shape = box
	s.add_child(col)
	add_child(s)
	return s


func generate_rungs():
	if not is_node_ready() or rung_multimesh == null:
		return
	var count = floor(height / spacing)
	var mm: MultiMesh = rung_multimesh.multimesh
	mm.instance_count = count
	mm.mesh = rung_mesh
	var rand = RandomNumberGenerator.new()
	rand.seed = 42

	for i in range(count):
		var t = Transform3D()
		var is_flipped_x: bool = (rand.randi() % 2 == 0)
		t.origin = Vector3(0, (i + 1) * spacing, 0)

		t.basis = Basis().rotated(Vector3.RIGHT, deg_to_rad(-90))
		if is_flipped_x:
			t.basis = t.basis.rotated(Vector3.UP, deg_to_rad(180))
		mm.set_instance_transform(i, t)


	if _climb_shape != null:
		_climb_shape.size = Vector3(0.6, height, 0.3)
		_climb_area.position = Vector3(0, height * 0.5, 0)
		_static_body.position = Vector3(0, height * 0.5, 0)

	if stile_left and stile_right:
		stile_left.scale = Vector3(stile_thickness, height, stile_thickness)
		stile_right.scale = Vector3(stile_thickness, height, stile_thickness)
		stile_left.position = Vector3(-0.3, height * 0.5, 0)
		stile_right.position = Vector3(0.3, height * 0.5, 0)


func set_static_collision_enabled(enabled: bool) -> void:
	if _static_body:
		_static_body.collision_layer = 1 if enabled else 0


func get_top_position() -> Vector3:
	return global_position + Vector3.UP * height + (-global_transform.basis.z * 1.0)

func get_bottom_position() -> Vector3:
	return global_position + (global_transform.basis.z * 1.0)
