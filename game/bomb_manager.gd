extends Node3D
class_name BombManager

@export var animation: AnimationPlayer
@export var bomb_scene: PackedScene
@export var player_inventory: HasInventory
@export var bomb_item: ItemData

@onready var aiming_preview: MeshInstance3D = $AimingPreview

var throw_force: float = 5
var can_throw: bool = true
var cooldown_timer: float = 0.0
const COOLDOWN: float = 3.0

var has_played_ready_animation: bool = false
var has_played_aim_animation: bool = false

func _ready():
	aiming_preview.visible = false

func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_throw = true

	var has_bomb := player_inventory == null or player_inventory.has_items(bomb_item, 1)
	if can_throw and has_bomb and Input.is_action_pressed("throw"):
		aim()

func _physics_process(_delta: float) -> void:
	if can_throw and Input.is_action_just_released("throw"):
		release()
		can_throw = false
		cooldown_timer = COOLDOWN

func aim():
	aiming_preview.visible = true
	if !has_played_ready_animation:
		animation.play("ReadyBomb")
		animation.queue("AimBomb")
		has_played_ready_animation = true

	
func release():
	has_played_ready_animation = false
	has_played_aim_animation = false
	aiming_preview.visible = false

	if player_inventory != null and bomb_item != null:
		if not player_inventory.has_items(bomb_item, 1):
			return
		player_inventory.remove_item(bomb_item, 1)

	var bomb: Bomb = bomb_scene.instantiate()
	get_tree().root.add_child(bomb)

	var forward := -global_transform.basis.z
	var desired_offset := 1.0
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + forward * desired_offset
	)
	q.collide_with_bodies = true
	q.collide_with_areas = false
	q.collision_mask = 4  # layer 3 — environment
	var hit := space.intersect_ray(q)
	var safe_offset := desired_offset
	if not hit.is_empty():
		safe_offset = global_position.distance_to(hit.position) - 0.1
	safe_offset = max(safe_offset, 0.1)

	bomb.global_position = global_position + forward * safe_offset
	bomb.apply_impulse(forward * throw_force)
