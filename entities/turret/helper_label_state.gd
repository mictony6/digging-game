extends Label3D

@export var state_machine: StateMachine

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = state_machine.state.name
	if state_machine.state.name == "Alert":
		if state_machine.state.target_entity:
			text += str(state_machine.state.target_entity.global_position)
