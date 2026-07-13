extends Node3D
class_name ToolManager

@export var current_tool: Tool
@export var tool_raycast: RayCast3D
@export var tool_area3d: Area3D
@export var hit_particles: PackedScene
@export var break_particles: PackedScene
@onready var beam: LaserBeam = current_tool.get_node("Beam")

@onready var flicker: ToolFlicker = $ToolFlicker
@onready var player: Player = owner as Player

const PARTICLE_POOL_SIZE = 5
var _particle_pool: Array[GPUParticles3D] = []
var _particle_index: int = 0

@export var arm_animations: AnimationTree
var _arm_playback: AnimationNodeStateMachinePlayback

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tool_area3d.body_entered.connect(_on_body_entered)
	tool_area3d.body_exited.connect(_on_body_exited)
	tool_raycast.enabled = false
	current_durability = _get_max_durability()
	_arm_playback = arm_animations.get("parameters/playback")
	DateManager.day_passed.connect(func(_days): repair())
	for i in PARTICLE_POOL_SIZE:
		var p: GPUParticles3D = hit_particles.instantiate()
		add_child(p)
		p.top_level = true
		p.emitting = false
		_particle_pool.append(p)

var bodies_in_aoe: Array[Node3D] = []

var tool_max_cooldown: float = 0.25
var tool_current_cooldown: float = 0.0

var is_pressing: bool = false

var current_durability: float = 100.0
signal durability_changed(current: float, max_val: float)

func _get_max_durability() -> float:
	return current_tool.tool_data.max_durability if current_tool and current_tool.tool_data else 100.0

func repair() -> void:
	current_durability = _get_max_durability()
	durability_changed.emit(current_durability, _get_max_durability())

func upgrade_max_durability(amount: float) -> void:
	current_tool.tool_data.max_durability += amount
	current_durability += amount
	durability_changed.emit(current_durability, _get_max_durability())

func upgrade_tier() -> void:
	current_tool.tool_data.tier_upgrade += 1

func upgrade_strength() -> void:
	var td := current_tool.tool_data
	td.strength_upgrade += (td.tier + td.tier_upgrade) * 0.05

func _process(_delta: float) -> void:
	is_pressing = Input.is_action_pressed("action")

func _physics_process(_delta: float) -> void:
	if beam.visible and tool_raycast.is_colliding():
		beam.aim(tool_raycast.get_collision_point(), tool_raycast.get_collision_normal())

## True when the player has movement input held down.
func is_player_moving() -> bool:
	return player.direction.length_squared() > 0.001

## True when the tool is aimed at something mineable and ready to swing.
func can_hit() -> bool:
	return is_pressing and current_durability > 0 and tool_raycast.is_colliding() and tool_raycast.get_collider() != null

## Executes a single swing: damage, particles, flicker, durability, cooldown.
func perform_hit() -> void:
	var collision_point := tool_raycast.get_collision_point()

	beam.aim(collision_point, tool_raycast.get_collision_normal())
	beam.show()

	tool_area3d.global_position = tool_raycast.get_collider().global_position
	tool_area3d.monitoring = true

	deal_damage_on_affected_bodies(bodies_in_aoe, get_total_damage(), get_total_tier(), tool_raycast.get_collider())
	play_particles(collision_point)

	flicker.global_position = collision_point
	flicker.flash()
	tool_current_cooldown = tool_max_cooldown

	current_durability = max(current_durability - 1.0, 0.0)
	durability_changed.emit(current_durability, _get_max_durability())

func stop_tool() -> void:
	beam.hide()
	travel_arm("HoldTool_IDLE")

func travel_arm(state_name: String) -> void:
	_arm_playback.travel(state_name)

func _on_body_entered(body: Node) -> void:
	if body.get_node_or_null("IsMineable") != null and body not in bodies_in_aoe:
		bodies_in_aoe.append(body)

func _on_body_exited(body: Node) -> void:
	if body in bodies_in_aoe:
		bodies_in_aoe.erase(body)


func get_total_damage():
	return current_tool.tool_data.strength + current_tool.tool_data.strength_upgrade

func get_total_tier():
	return current_tool.tool_data.tier + current_tool.tool_data.tier_upgrade

func deal_damage_on_affected_bodies(bodies: Array[Node3D], damage: float, tier: int, main_body: Node):
	for body in bodies:
		var mineable: IsMineable = body.get_node_or_null("IsMineable")
		if mineable:
			shake_target(body)
			if body == main_body:
				mineable.mine(damage, tool_raycast.get_collision_point(), tier)
			else:
				mineable.mine(damage / 4.0, Vector3.ZERO, tier)

func play_particles(collision_point: Vector3):
	var p := _particle_pool[_particle_index]
	_particle_index = (_particle_index + 1) % PARTICLE_POOL_SIZE

	p.global_position = collision_point
	var collision_normal = tool_raycast.get_collision_normal()
	var up = Vector3.RIGHT if collision_normal.is_equal_approx(Vector3.UP) else Vector3.UP
	p.look_at(collision_point + collision_normal, up)
	p.restart()


func shake_target(target: Node3D):
	var base := target.global_position
	var ray_dir := -tool_raycast.global_transform.basis.z
	var push := ray_dir * 0.05

	var tween := target.create_tween()

	tween.tween_property(target, "global_position", base + push, 0.03)
	tween.tween_property(target, "global_position", base, 0.06)
