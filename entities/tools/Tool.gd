@tool
extends Node3D

@export var tool_data: ToolData:
	set(value):
		tool_data = value
		if Engine.is_editor_hint():
			load_tool()


@export var tool_mesh_instance: MeshInstance3D
@export var animation_player: AnimationPlayer
@export var debug_mode: bool = false
var mouse_movement: Vector2
var velocity: Vector3 = Vector3.ZERO
var last_position: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_tool()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_movement = event.relative

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and debug_mode:
		position = tool_data.position
		rotation_degrees = tool_data.rotation
	if Engine.is_editor_hint():
		return


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Calculate velocity
	velocity = (global_position - last_position) / delta
	last_position = global_position
	sway_tool(delta)


func load_tool() -> void:
	if tool_data == null:
		return
	tool_mesh_instance.mesh = tool_data.mesh

	position = tool_data.position
	rotation_degrees = tool_data.rotation

func sway_tool(delta: float) -> void:
	mouse_movement = mouse_movement.clamp(tool_data.sway_min, tool_data.sway_max)
	mouse_movement = mouse_movement.lerp(Vector2.ZERO, 5 * delta)

	#lerp position
	position.x = lerpf(position.x, tool_data.position.x - (mouse_movement.x * tool_data.sway_amount_position) * delta, tool_data.sway_speed_position)
	position.y = lerpf(position.y, tool_data.position.y + ((mouse_movement.y - velocity.y * 2) * tool_data.sway_amount_position) * delta, tool_data.sway_speed_position)

	#lerp rotation
	rotation_degrees.y = lerpf(rotation_degrees.y, tool_data.rotation.y - (mouse_movement.x * tool_data.sway_amount_rotation) * delta, tool_data.sway_speed_rotation)
	rotation_degrees.x = lerpf(rotation_degrees.x, tool_data.rotation.x + ((mouse_movement.y - velocity.y * 2) * tool_data.sway_amount_rotation) * delta, tool_data.sway_speed_rotation)

func use_tool() -> void:
	pass
