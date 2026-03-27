extends PathFollow3D

var player_in: bool = false
var player: Player = null
@onready var forward_button: Node3D
var speed: float = 0.0
var target_speed: float = 0.0
var MAX_SPEED = 3.0


func _on_area_inside_body_entered(body: Node3D) -> void:
	if body is Player:
		player_in = true
		player = body


func _on_area_inside_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in = false
		player = null


func _on_forward_is_selectable_selected(_player: Player, _tool: Tool) -> void:
	if !player_in: return

	_player.board_minecart(self )
	add_speed(1.0)

func _on_backward_is_selectable_selected(_player: Player, _tool: Tool) -> void:
	if !player_in: return

	add_speed(-1.0)
	
func add_speed(addtl_speed: float):
	target_speed = clamp(target_speed + addtl_speed, -MAX_SPEED, MAX_SPEED, )


func _physics_process(delta):
	speed = move_toward(speed, target_speed, delta * 5.0)
	progress += speed * delta
	if progress_ratio == 0 or progress_ratio == 1.0:
		stop()

func stop():
	speed = 0
	target_speed = 0