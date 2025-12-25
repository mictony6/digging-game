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


func _ready() -> void:
	if head == null:
		head = get_node("Head");

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	#full screen toggle
	if event is InputEventKey:
		if event.pressed and event.keycode == Key.KEY_F11:
			get_window().mode = Window.MODE_FULLSCREEN if get_window().mode != Window.MODE_FULLSCREEN else Window.MODE_WINDOWED

func _process(delta: float) -> void:
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

# func _physics_process(delta: float) -> void:
# 	velocity.y -= (gravity * delta);
# 	if is_on_floor():
# 		acceleration = ground_acceleration
# 		if Input.is_action_just_pressed("jump"):
# 			jump()
# 		elif buffered_jump_timer > 0.0:
# 			jump()
# 	else:
# 		acceleration = air_acceleration

# 	velocity.x = move_toward(velocity.x, direction.x * SPEED, acceleration * delta)
# 	velocity.z = move_toward(velocity.z, direction.z * SPEED, acceleration * delta)
# 	move_and_slide()
