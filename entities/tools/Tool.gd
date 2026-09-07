@tool
extends Node3D
class_name Tool

@export var tool_data: ToolData:
	get:
		return _tool_data
	set(value):
		_tool_data = value
		if Engine.is_editor_hint():
			load_tool(value)

var _tool_data: ToolData
var tool_scene: Node3D
@export var animation_player: AnimationPlayer
@export var debug_mode: bool = false
var mouse_movement: Vector2

# Velocity for sway calculations
var velocity: Vector3 = Vector3.ZERO
var last_position: Vector3 = Vector3.ZERO

# tool state variables

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_tool(tool_data)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and debug_mode:
		tool_scene.position = tool_data.position
		tool_scene.rotation_degrees = tool_data.rotation
	if Engine.is_editor_hint():
		return


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Calculate velocity
	velocity = (global_position - last_position) / delta
	last_position = global_position
	# sway_tool(delta)


func load_tool(data: ToolData) -> void:
	if data == null:
		return
	_tool_data = data
	if tool_scene:
		tool_scene.queue_free()
	var scene: Node3D = data.scene.instantiate()
	add_child(scene)
	tool_scene = scene

	tool_scene.position = data.position
	tool_scene.rotation_degrees = data.rotation

