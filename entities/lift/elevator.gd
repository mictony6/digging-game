extends Node3D
var is_open: bool = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collider: CollisionShape3D = $StaticBody3D/DoorCollisionShape
func _ready():
	$IsSelectable.selected.connect(_on_is_selectable_selected)

func _on_is_selectable_selected(_player: Player, _tool: Tool) -> void:
	if is_open:
		close()
	else:
		open()

func open():
	animation_player.play("OpenDoor")
	await get_tree().create_timer(animation_player.current_animation_length * 0.4).timeout
	collider.disabled = true
	is_open = true
	
func close():
	animation_player.play("OpenDoor", -1, -1.0, true)
	await get_tree().create_timer(animation_player.current_animation_length * 0.5).timeout
	collider.disabled = false
	is_open = false
