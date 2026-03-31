extends CharacterBody3D
class_name Player

@export var head: Node3D

# Movement variables
@export var SPEED: float = 2;
@export var SPRINT_SPEED: float = 3;
var JUMP_FORCE: float = 4;
@export var JUMP_HEIGHT: float = 1.3;
@export var JUMP_HALF_TIME: float = 0.35;
@export var FALL_GRAVITY_MULTIPLIER: float = 1.3;
var acceleration: float = 15.0;
var air_acceleration: float = 2.5;
var ground_acceleration: float = 15.0;

var direction: Vector3 = Vector3.ZERO;
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

# Jump buffering
var buffered_jump_timer: float = 0.0
var buffered_jump_time: float = 0.05

var height: float = 1.5

@onready var state_machine: StateMachine = $StateMachine

# Water / swimming
var in_water: bool = false
var _water_area_count: int = 0

#status effects
var is_poisoned: bool = false
var is_suffocating: bool = false
var active_depletion_rate_multiplier: float = 0.0


#components
@onready var health: HasHealth = $HasHealth
@onready var oxygen: HasOxygen = $HasOxygen
@onready var inventory: HasInventory = $HasInventory

# Inventory UI — assign in the inspector (add InventoryUI.tscn to your HUD)
@export var inventory_ui: InventoryUI

# Pickup settings
@export var pickup_radius: float = 2.5
const HOLD_PICKUP_TIME := 0.4 # seconds to hold E before picking all

var inventory_open: bool = false
var _hold_pickup_timer: float = 0.0
var _holding_pickup: bool = false

func _ready() -> void:
	assert(health != null, "Player must have health component")
	assert(oxygen != null, "Player must have oxygen component")
	if head == null:
		head = get_node("Head");
	gravity = (2 * JUMP_HEIGHT) / (pow(JUMP_HALF_TIME, 2))
	JUMP_FORCE = sqrt(2 * gravity * JUMP_HEIGHT)


	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Swim detector raised to y=0.3 (above center) so the player is already
	# well submerged before swim triggers, keeping the camera lower in the water.
	var swim_area := Area3D.new()
	swim_area.name = "SwimDetector"
	swim_area.collision_layer = 0
	swim_area.collision_mask = 4  # matches water_volume layer
	swim_area.position = Vector3(0, 0.3, 0)
	var swim_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.2
	swim_shape.shape = sphere
	swim_area.add_child(swim_shape)
	add_child(swim_area)
	swim_area.area_entered.connect(_on_water_entered)
	swim_area.area_exited.connect(_on_water_exited)

func _input(event: InputEvent) -> void:
	#full screen toggle
	if event is InputEventKey:
		if event.pressed and event.keycode == Key.KEY_F11:
			get_window().mode = Window.MODE_FULLSCREEN if get_window().mode != Window.MODE_FULLSCREEN else Window.MODE_WINDOWED
		if event.pressed and event.keycode == Key.KEY_F1:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("inventory_toggle"):
		_toggle_inventory()

func _process(delta: float) -> void:
	$Control/StateLabel.text = state_machine.state.name

	# Block movement and pickup while inventory is open
	if inventory_open:
		direction = Vector3.ZERO
		_holding_pickup = false
		_hold_pickup_timer = 0.0
		return

	var h_movement = Input.get_axis("move_left", "move_right");
	var z_movement = Input.get_axis("move_backward", "move_forward");
	direction.x = h_movement;
	direction.z = - z_movement;

	# make direction relative to camera
	direction = direction.rotated(Vector3.UP, head.global_rotation.y);
	direction = direction.normalized();

	# Jump buffering
	if Input.is_action_pressed("jump"):
		buffered_jump_timer = buffered_jump_time
	buffered_jump_timer -= delta
	buffered_jump_timer = max(buffered_jump_timer, 0.0)

	# E-key pickup: hold to pick all, tap to pick nearest
	if Input.is_action_pressed("pickup"):
		if not _holding_pickup:
			_hold_pickup_timer += delta
			if _hold_pickup_timer >= HOLD_PICKUP_TIME:
				_holding_pickup = true
				_pickup_all_in_range()
	else:
		if not _holding_pickup and _hold_pickup_timer > 0.0:
			_pickup_nearest()
		_hold_pickup_timer = 0.0
		_holding_pickup = false

	# suffocation and oxygen
	if is_suffocating:
		if !oxygen.is_empty():
			oxygen.remove_oxygen(PlayerData.depletion_rate
			* active_depletion_rate_multiplier
			* delta)
		else:
			health.take_damage(11 * delta)
	elif !oxygen.is_full():
		oxygen.add_oxygen(10 * delta)

	
func _on_water_entered(area: Area3D) -> void:
	if area.is_in_group("water_volume"):
		_water_area_count += 1
		in_water = true

func _on_water_exited(area: Area3D) -> void:
	if area.is_in_group("water_volume"):
		_water_area_count -= 1
		in_water = _water_area_count > 0

func board_minecart(cart: PathFollow3D) -> void:
	state_machine._transition_to_next_state("RidingMinecart", {"cart": cart})

func has_buffered_jump():
	return buffered_jump_timer > 0.0

func determine_suffocation(status: bool, difficulty: int):
	is_suffocating = status
	active_depletion_rate_multiplier = float(difficulty) if is_suffocating else 1.0

func _toggle_inventory() -> void:
	inventory_open = !inventory_open
	if inventory_ui == null:
		return
	if inventory_open:
		inventory_ui.open(inventory.get_inventory())
	else:
		inventory_ui.close()

func _get_nearby_pickups() -> Array:
	var result: Array = []
	for node in get_tree().get_nodes_in_group("pickups"):
		if node is PickupItem and node.global_position.distance_to(global_position) <= pickup_radius:
			result.append(node)
	return result

func _pickup_nearest() -> void:
	var nearby := _get_nearby_pickups()
	if nearby.is_empty():
		return
	var closest = nearby[0]
	var closest_dist: float = closest.global_position.distance_to(global_position)
	for item in nearby:
		var d: float = item.global_position.distance_to(global_position)
		if d < closest_dist:
			closest = item
			closest_dist = d
	_collect(closest)

func _pickup_all_in_range() -> void:
	for item in _get_nearby_pickups():
		_collect(item)

func _collect(pickup: PickupItem) -> void:
	if pickup._attracting:
		return
	pickup.picked_up.connect(func(item, qty): inventory.add_item(item, qty))
	pickup.attract_to(self )
