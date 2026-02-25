extends TurretState
@export var bomb: PackedScene

func enter(previous_state_path: String, data := {}) -> void:
	launch_bomb()
	finished.emit(IDLE)

func launch_bomb():
	var bomb_instance: InstantBomb = bomb.instantiate()
	owner.add_child(bomb_instance)
	bomb_instance.global_position = %BombSpawnLoc.global_position
	bomb_instance.apply_impulse(-head.global_transform.basis.z * 10)
