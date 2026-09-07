extends Node3D
class_name ToolManager

enum Attachment {MINING, SHOOTING, SCANNER}

@export var current_tool: Tool
@export var tool_raycast: RayCast3D
@export var tool_area3d: Area3D
@export var hit_particles: PackedScene
@export var break_particles: PackedScene
@onready var beam: LaserBeam = current_tool.get_node("Beam")
@onready var flicker: ToolFlicker = $ToolFlicker
@onready var player: Player = owner as Player

@export var mining_tool_data: ToolData
@export var shooting_tool_data: ToolData
@export var scanner_tool_data: ToolData

## Shared battery capacity, same no matter which attachment is equipped —
## a TotK-style single meter, not a per-tool durability pool.
@export var max_durability: float = 250.0

var current_attachment: Attachment = Attachment.MINING
signal attachment_changed(attachment: Attachment, tool_data: ToolData)

const PARTICLE_POOL_SIZE = 5
var _particle_pool: Array[GPUParticles3D] = []
var _particle_index: int = 0

@export var arm_animations: AnimationTree
var _arm_playback: AnimationNodeStateMachinePlayback

var tool_max_cooldown: float = 0.25
var tool_current_cooldown: float = 0.0

var pressed: bool = false
var _bodies_in_aoe: Array[Node3D] = []

var current_durability: float = 100.0
signal durability_changed(current: float, max_val: float)

# Shop UI widgets are rebuilt each time the shop opens, so purchase counts
# live here where they survive across opens.
var upgrade_counts: Dictionary = {}

func _ready() -> void:
	DateManager.day_passed.connect(func(_days): repair())

	tool_area3d.body_entered.connect(_on_body_entered)
	tool_area3d.body_exited.connect(_on_body_exited)

	tool_raycast.enabled = false

	current_durability = _get_max_durability()

	_arm_playback = arm_animations.get("parameters/playback")

	_particle_pool = _populate_hit_particles(hit_particles, PARTICLE_POOL_SIZE, self)

	beam.hide()
	flicker.hide()
func _process(_delta: float) -> void:
	pressed = Input.is_action_pressed("action") \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

func _physics_process(_delta: float) -> void:
	if beam.visible and tool_raycast.is_colliding():
		beam.aim(tool_raycast.get_collision_point(), tool_raycast.get_collision_normal())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("equip_mining"):
		equip_attachment(Attachment.MINING)
	elif event.is_action_pressed("equip_shooting"):
		equip_attachment(Attachment.SHOOTING)
	elif event.is_action_pressed("equip_scanner"):
		equip_attachment(Attachment.SCANNER)


## Swaps the held mesh to the given attachment's visual and resets the tool
## state machine to Idle so a stale leaf state (e.g. mid-swing) can't keep
## running with the wrong attachment's data.
func equip_attachment(attachment: Attachment) -> void:
	if attachment == current_attachment:
		return
	current_attachment = attachment
	var data := _tool_data_for(attachment)

	current_tool.load_tool(data)

	attachment_changed.emit(attachment, data)

func _tool_data_for(attachment: Attachment) -> ToolData:
	match attachment:
		Attachment.SHOOTING: return shooting_tool_data
		Attachment.SCANNER: return scanner_tool_data
		_: return mining_tool_data


# helper functions

func _populate_hit_particles(particle_scene: PackedScene, pool_size: int, parent: Node3D):
	var pool: Array[GPUParticles3D] = []
	for i in pool_size:
		var p: GPUParticles3D = particle_scene.instantiate()
		parent.add_child(p)
		p.top_level = true
		p.emitting = false
		pool.append(p)
	return pool
		
func _get_max_durability() -> float:
	return max_durability

func repair() -> void:
	current_durability = _get_max_durability()
	durability_changed.emit(current_durability, _get_max_durability())

func get_upgrade_count(type: UpgradeItem.UpgradeType) -> int:
	return upgrade_counts.get(type, 0)

func record_upgrade(type: UpgradeItem.UpgradeType) -> void:
	upgrade_counts[type] = get_upgrade_count(type) + 1

## upgrade_tier()/upgrade_strength() always target the mining tool
## specifically, not whichever attachment happens to be equipped — the shop
## UI's labels ("MINING TIER", "MINING STRENGTH") are Mining-only, and
## current_tool.tool_data is swappable now that attachments exist.
## upgrade_max_durability() is different: the battery is shared across every
## attachment (see max_durability above), so it always applies regardless of
## what's equipped.
func upgrade_max_durability(amount: float) -> void:
	max_durability += amount
	current_durability += amount
	durability_changed.emit(current_durability, _get_max_durability())

func upgrade_tier() -> void:
	mining_tool_data.tier_upgrade += 1
	attachment_changed.emit(current_attachment, mining_tool_data)

func upgrade_strength() -> void:
	mining_tool_data.strength_upgrade += (mining_tool_data.tier + mining_tool_data.tier_upgrade) * 0.05
	attachment_changed.emit(current_attachment, mining_tool_data)


## True when the player has movement input held down.
func is_player_moving() -> bool:
	return player.direction.length_squared() > 0.001

## True when the tool is aimed at something mineable and ready to swing.
func can_hit() -> bool:
	return pressed and current_durability > 0 and tool_raycast.is_colliding() and tool_raycast.get_collider() != null

## Executes a single swing: damage, particles, flicker, durability, cooldown.
func perform_hit() -> void:
	var collision_point := tool_raycast.get_collision_point()

	beam.aim(collision_point, tool_raycast.get_collision_normal())
	beam.show()

	tool_area3d.global_position = tool_raycast.get_collider().global_position
	tool_area3d.monitoring = true

	deal_damage_on_affected_bodies(_bodies_in_aoe, get_total_damage(), get_total_tier(), tool_raycast.get_collider())
	play_particles(collision_point)

	flicker.global_position = collision_point + tool_raycast.get_collision_normal() * 0.1
	flicker.flash()
	tool_current_cooldown = tool_max_cooldown

	current_durability = max(current_durability - current_tool.tool_data.battery_cost, 0.0)
	durability_changed.emit(current_durability, _get_max_durability())

func travel_arm(state_name: String) -> void:
	_arm_playback.travel(state_name)

func _on_body_entered(body: Node) -> void:
	var is_interactable := body.is_in_group("IsMineable") or body.is_in_group("IsLaserInteractable")
	if is_interactable and body not in _bodies_in_aoe:
		_bodies_in_aoe.append(body)

func _on_body_exited(body: Node) -> void:
	if body in _bodies_in_aoe:
		_bodies_in_aoe.erase(body)


func get_total_damage():
	return current_tool.tool_data.strength + current_tool.tool_data.strength_upgrade

func get_total_tier():
	return current_tool.tool_data.tier + current_tool.tool_data.tier_upgrade

func deal_damage_on_affected_bodies(bodies: Array[Node3D], damage: float, tier: int, main_body: Node):
	for body in bodies:
		if body.is_in_group("IsMineable"):
			var mineable: IsMineable = body.get_node_or_null("IsMineable")
			shake_target(body)
			if body == main_body:
				mineable.mine(damage, tool_raycast.get_collision_point(), tier)
			else:
				mineable.mine(damage / 4.0, Vector3.ZERO, tier)


func play_particles(collision_point: Vector3):
	var p := _particle_pool[_particle_index]
	_particle_index = (_particle_index + 1) % PARTICLE_POOL_SIZE

	p.global_position = collision_point
	var collision_normal := tool_raycast.get_collision_normal()
	# Particles emit along local +Y, so rotate +Y onto the surface normal.
	p.global_basis = Basis(Quaternion(Vector3.UP, collision_normal))
	p.restart()


func shake_target(target: Node3D):
	var base := target.global_position
	var ray_dir := -tool_raycast.global_transform.basis.z
	var push := ray_dir * 0.05

	var tween := target.create_tween()

	tween.tween_property(target, "global_position", base + push, 0.03)
	tween.tween_property(target, "global_position", base, 0.06)
