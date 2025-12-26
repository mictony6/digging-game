extends Node3D
class_name BombManager


@export var bomb_scene: PackedScene
@onready var aiming_preview: MeshInstance3D = $AimingPreview

var throw_force: float = 10
var can_throw: bool = true
var cooldown_timer: float = 3.0


func _ready():
	aiming_preview.visible = false

func _process(delta: float) -> void:
	if !can_throw:
		cooldown_timer -= delta
	if cooldown_timer <= 0:
		can_throw = true
		cooldown_timer = 3.0


	if can_throw and Input.is_action_pressed("throw"):
		aim()
func _physics_process(delta: float) -> void:
	if can_throw and Input.is_action_just_released("throw"):
		release()
		can_throw = false
		return

func aim():
	aiming_preview.visible = true

	
func release():
	aiming_preview.visible = false
	var bomb: Bomb = bomb_scene.instantiate()
	get_tree().root.add_child(bomb)
	bomb.global_position = global_position + (-global_transform.basis.z)
	bomb.apply_impulse(-global_transform.basis.z * throw_force)
