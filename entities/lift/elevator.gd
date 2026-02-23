extends Node3D
var is_open: bool = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collider: CollisionShape3D = $StaticBody3D/DoorCollisionShape

var player: Player
var player_in: bool = false
@export var starting_point: Node3D
@export var end_point: Node3D
@export var levelloader: Node3D
var is_at_end: bool = false
var animating: bool = false

@onready var fader: MeshInstance3D = $Fader
func _ready():
	$IsSelectable.selected.connect(_on_is_selectable_selected)

func _on_is_selectable_selected(_player: Player, _tool: Tool) -> void:
	if animating:
		$IsSelectable.switch_interaction_label()
		return
	if is_open:
		close()
	else:
		open()

func open():
	animation_player.play("OpenDoor")
	animating = true
	await get_tree().create_timer(animation_player.current_animation_length * 0.4).timeout
	collider.disabled = true
	is_open = true
	animating = false
	
func close():
	animation_player.play_backwards("OpenDoor")
	animating = true
	await get_tree().create_timer(animation_player.current_animation_length * 0.5).timeout
	collider.disabled = false
	is_open = false
	await get_tree().create_timer(animation_player.current_animation_length * 0.5).timeout
	animating = false
	if !player_in: return
	await play_fade_out()
	var p_relative_pos: Vector3 = player.global_position - global_position
	if !is_at_end:
		global_position = end_point.global_position
		player.global_position = global_position + p_relative_pos
		is_at_end = true
	else:
		global_position = starting_point.global_position
		player.global_position = global_position + p_relative_pos
		is_at_end = false
	await play_fade_in()

func play_fade_out():
	var tween: Tween = create_tween()
	tween.tween_property(fader, "transparency", 0.0, 0.25)
	tween.tween_interval(0.25)
	return tween.finished
func play_fade_in():
	var tween: Tween = create_tween()
	tween.tween_property(fader, "transparency", 1.0, 0.25)
	tween.tween_interval(0.25)
	return tween.finished


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body
		player_in = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player:
		player = null
		player_in = false
