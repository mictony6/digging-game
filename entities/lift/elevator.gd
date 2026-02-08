extends Node3D
var is_open: bool = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collider: CollisionShape3D = $StaticBody3D/DoorCollisionShape

var player_in: bool = false
@export var starting_point: Node3D
@export var end_point: Node3D
@export var levelloader: Node3D
var is_at_end: bool = false
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
	await get_tree().create_timer(animation_player.current_animation_length * 0.5).timeout
	if !is_at_end and player_in:
		global_position = end_point.global_position
		is_at_end = true
	else:
		global_position = starting_point.global_position
		is_at_end = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player_in = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in = false
