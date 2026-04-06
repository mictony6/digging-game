extends Node3D
class_name ToolManager


@export var current_tool: Tool
@export var tool_raycast: RayCast3D
@export var tool_area3d: Area3D
@export var hit_particles: PackedScene
@export var break_particles: PackedScene
@onready var beam: Node3D = $Beam

@onready var flicker: ToolFlicker = $ToolFlicker

const PARTICLE_POOL_SIZE = 5
var _particle_pool: Array[GPUParticles3D] = []
var _particle_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tool_area3d.body_entered.connect(_on_body_entered)
	tool_area3d.body_exited.connect(_on_body_exited)
	tool_raycast.enabled = false
	for i in PARTICLE_POOL_SIZE:
		var p: GPUParticles3D = hit_particles.instantiate()
		add_child(p)
		p.top_level = true
		p.emitting = false
		_particle_pool.append(p)
	
var bodies_in_aoe: Array[Rock] = []

var tool_max_cooldown: float = 0.25
var tool_current_cooldown: float = 0.0

var _pressing: bool = false

func _process(_delta: float) -> void:
	_pressing = Input.is_action_pressed("action")

func _physics_process(delta: float) -> void:
	tool_current_cooldown = max(tool_current_cooldown - delta, 0.0)
	if tool_current_cooldown > 0:
		return
	if _pressing:
		tool_raycast.force_raycast_update()
	if _pressing and tool_raycast.is_colliding() and tool_raycast.get_collider() != null:
		var collision_point = tool_raycast.get_collision_point()

		beam.show()

		tool_area3d.global_position = tool_raycast.get_collider().global_position
		tool_area3d.monitoring = true

		deal_damage_on_affected_rocks(bodies_in_aoe, get_total_damage(), get_total_tier(), tool_raycast.get_collider())
		play_particles(collision_point)

		flicker.global_position = collision_point
		flicker.flash()
		tool_current_cooldown = tool_max_cooldown
	else:
		beam.hide()


func _on_body_entered(body: Node) -> void:
	if body is Rock and body not in bodies_in_aoe:
		bodies_in_aoe.append(body)
		# body.destroyed.connect(_on_rock_destroyed)

func _on_body_exited(body: Node) -> void:
	if body is Rock and body in bodies_in_aoe:
		bodies_in_aoe.erase(body)
		# body.destroyed.disconnect(_on_rock_destroyed)


func get_total_damage():
	return current_tool.tool_data.strength + current_tool.tool_data.strength_upgrade

func get_total_tier():
	return current_tool.tool_data.tier + current_tool.tool_data.tier_upgrade

func deal_damage_on_affected_rocks(rocks: Array[Rock], damage, tier, main_rock):
	for rock in rocks:
		if rock.rock_data.tier <= tier:
			shake_target(rock)

			if rock == main_rock:
				rock.take_damage(damage, tool_raycast.get_collision_point())
			else:
				rock.take_damage(damage / 4.0)

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
