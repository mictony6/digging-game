extends PlayerState
var CROUCH_SPEED: float = 1
@export var collider: CollisionShape3D
@export var head: Node3D
var default_height: float = 1.5
var crouch_height: float
var default_head_y: float
var crouch_head_y: float
var tween: Tween
var CROUCH_DOWN_SPEED: float = 0.25
var UNCROUCH_SPEED: float = 0.3

func _ready():
	super._ready()
	crouch_height = default_height / 2.0
	default_head_y = head.position.y
	crouch_head_y = default_head_y - crouch_height
func enter(previous_state_path: String, data := {}) -> void:
	player.acceleration = player.ground_acceleration
	var capsule: CapsuleShape3D = collider.shape

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(head, "position:y", crouch_head_y, CROUCH_DOWN_SPEED)
	capsule.height = default_height / 2.0
	collider.position.y = - default_height / 4.0
	
func exit() -> void:
	var capsule: CapsuleShape3D = collider.shape
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(head, "position:y", default_head_y, UNCROUCH_SPEED)
	capsule.height = default_height
	collider.position.y = 0.0


func physics_update(delta: float) -> void:
	player.velocity.y -= (player.gravity * delta);

	player.velocity.x = move_toward(player.velocity.x, player.direction.x * CROUCH_SPEED, player.acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, player.direction.z * CROUCH_SPEED, player.acceleration * delta)
	player.move_and_slide()
	next_state_conditions()

func next_state_conditions():
	if !can_uncrouch():
		return
	if player.is_on_floor():
		if !Input.is_action_pressed("crouch"):
			finished.emit(MOVE)

func can_uncrouch() -> bool:
	var space_state = player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = 0b100110


	query.from = player.global_position
	query.to = player.global_position + Vector3(0, crouch_height, 0)

	var result = space_state.intersect_ray(query)
	if result and result.collider:
		return false
	else:
		return true
