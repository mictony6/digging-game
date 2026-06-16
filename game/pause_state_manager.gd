extends Node

var paused: bool = false

func set_paused(value: bool, context: Node) -> void:
    paused = value
    context.get_tree().paused = value

func is_paused() -> bool:
    return paused
