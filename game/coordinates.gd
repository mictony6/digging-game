extends Control


@onready var x_label: Label = $"X"
@onready var y_label: Label = $"Y"
@onready var z_label: Label = $"Z"
@export var player: Player

func _process(delta: float) -> void:
	assert(player != null, "Player should be assigned to the coordinates system!")

	x_label.text = str(round(player.global_position.x)) + " :X"
	y_label.text = str(round(player.global_position.y)) + " :Y"
	z_label.text = str(round(-player.global_position.z)) + " :Z"
