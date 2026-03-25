extends PlayerState

var cart: PathFollow3D = null

func enter(previous_state_path: String, data := {}) -> void:
	cart = data.get("cart", null)
	player.velocity = Vector3.ZERO


func physics_update(_delta: float) -> void:
	if cart == null:
		finished.emit(FALL)
		return

	player.global_position = cart.global_position + Vector3(0, 0.6, 0)
	player.velocity = Vector3.ZERO

	if Input.is_action_just_pressed("jump"):
		cart.stop()
		finished.emit(FALL)
		cart = null
