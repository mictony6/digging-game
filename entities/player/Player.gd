extends CharacterBody3D
class_name Player

@export var head: Node3D

# Movement variables
@export var SPEED: float = 2;
@export var SPRINT_SPEED: float = 10;
@export var JUMP_FORCE = 4;
var acceleration: float = 15.0;
var air_acceleration: float = 2.5;
var ground_acceleration: float = 15.0;

var direction: Vector3 = Vector3.ZERO;
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

# Jump buffering
var buffered_jump_timer: float = 0.0
var buffered_jump_time: float = 0.05

@onready var state_machine: StateMachine = $StateMachine

#status effects
var is_poisoned: bool = false
var is_suffocating: bool = false
var active_depletion_rate_multiplier: float = 0.0

func _ready() -> void:
	if head == null:
		head = get_node("Head");

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	#full screen toggle
	if event is InputEventKey:
		if event.pressed and event.keycode == Key.KEY_F11:
			get_window().mode = Window.MODE_FULLSCREEN if get_window().mode != Window.MODE_FULLSCREEN else Window.MODE_WINDOWED
		if event.pressed and event.keycode == Key.KEY_F1:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	$Control/StateLabel.text = state_machine.state.name
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

	# suffocation and oxygen
	if is_suffocating:
		if PlayerData.has_oxygen():
			PlayerData.remove_oxygen(PlayerData.depletion_rate
			* active_depletion_rate_multiplier
			* delta)
		else:
			PlayerData.remove_health(11 * delta)
	elif PlayerData.oxygen_not_full():
		PlayerData.add_oxygen(10 * delta)

func has_buffered_jump():
	return buffered_jump_timer > 0.0

func determine_suffocation(status: bool, difficulty: int):
	is_suffocating = status
	active_depletion_rate_multiplier = difficulty if is_suffocating else 1.0
