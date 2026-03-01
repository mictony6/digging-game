extends Node3D
class_name Turret

@onready var head: AnimatableBody3D = $Head

@onready var state_machine: StateMachine = $StateMachine
@onready var sounds : Node3D = $Sounds


func _on_has_health_death() -> void:
	queue_free()