extends Resource
class_name ToolData

@export var name: String = "New Tool"
@export var tier: int = 1
@export var strength: int = 1

@export_category("Visuals")
@export var mesh: Mesh

@export_category("Positioning")
@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO

@export_category("Tool Sway")
@export var sway_min: Vector2 = Vector2(-20.0, -20.0)
@export var sway_max: Vector2 = Vector2(20.0, 20.0)
@export_range(0, 0.2, 0.01) var sway_speed_position: float = 0.07
@export_range(0, 0.2, 0.01) var sway_speed_rotation: float = 0.1
@export_range(0, 0.25, 0.01) var sway_amount_position: float = 0.1
@export_range(0, 50, 0.1) var sway_amount_rotation: float = 30.
