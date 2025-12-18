extends Node3D
class_name Rock

@export var rock_data: RockData
var current_health: int

func _ready():
    current_health = rock_data.max_health

func take_damage(damage: int):
    if not rock_data.is_destructible:
        return
    current_health -= damage
    if current_health <= 0:
        destroy()
func destroy():
    queue_free()