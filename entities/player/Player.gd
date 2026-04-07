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

# Ladders
var overlapping_ladders: Array = []
var current_ladder: LadderGenerator = null

# Status effects
var is_poisoned: bool = false
var is_suffocating: bool = false
var active_depletion_rate_multiplier: float = 0.0

# Components
@onready var health: HasHealth = $HasHealth
@onready var oxygen: HasOxygen = $HasOxygen
@onready var inventory: HasInventory = $HasInventory
@onready var pickup_component: PickupComponent = $PickupComponent

@export var shop_ui: Control

var inventory_open: bool = false

signal inventory_opened(inventory_data)
signal inventory_closed()

func _ready() -> void:
	assert(health != null, "Player must have health component")
	assert(oxygen != null, "Player must have oxygen component")
	if head == null:
		head = get_node("Head");
	gravity = (2 * JUMP_HEIGHT) / (pow(JUMP_HALF_TIME, 2))
	JUMP_FORCE = sqrt(2 * gravity * JUMP_HEIGHT)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	pickup_component.item_collected.connect(func(item, qty): inventory.add_item(item, qty))

	var swim_area := $SwimDetector
	swim_area.area_entered.connect(_on_water_entered)
	swim_area.area_exited.connect(_on_water_exited)

	%LadderDetector.area_entered.connect(_on_ladder_entered)
	%LadderDetector.area_exited.connect(_on_ladder_exited)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_toggle"):
		_toggle_inventory()

func _process(delta: float) -> void:
	$Control/StateLabel.text = state_machine.state.name

	if inventory_open:
		direction = Vector3.ZERO
		pickup_component.reset()
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

	pickup_component.process_input(delta)

	# Oxygen / suffocation
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

func _on_ladder_entered(area: Area3D) -> void:
	if area.is_in_group("ladder"):
		overlapping_ladders.append(area)

func _on_ladder_exited(area: Area3D) -> void:
	overlapping_ladders.erase(area)

func board_minecart(cart: PathFollow3D) -> void:
	state_machine._transition_to_next_state("RidingMinecart", {"cart": cart})

func has_buffered_jump():
	return buffered_jump_timer > 0.0

func determine_suffocation(status: bool, difficulty: int):
	is_suffocating = status
	active_depletion_rate_multiplier = float(difficulty) if is_suffocating else 1.0

func _toggle_inventory() -> void:
	if shop_ui != null and shop_ui.visible:
		return
	inventory_open = !inventory_open
	if inventory_open:
		inventory_opened.emit(inventory.get_inventory())
	else:
		inventory_closed.emit()
