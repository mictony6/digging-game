extends RigidBody3D
class_name Bomb

@onready var area: Area3D = $Area3D
signal exploded(position: Vector3)
var damage = 67

@onready var bomb_light: OmniLight3D = $BombLight

const FUSE_DURATION = 3.0
var _time_remaining: float = FUSE_DURATION
var _flash_timer: float = 0.0
var _light_tween: Tween
var _exploding: bool = false

func _ready() -> void:
	get_tree().create_timer(FUSE_DURATION).timeout.connect(explode)

func _flash_light() -> void:
	if _light_tween:
		_light_tween.kill()
	bomb_light.light_energy = 2.0
	var t = clamp(1.0 - (_time_remaining / FUSE_DURATION), 0.0, 1.0)
	var fade = lerp(0.5, 0.06, t)
	_light_tween = create_tween()
	_light_tween.tween_property(bomb_light, "light_energy", 0.0, fade)

func explode():
	_exploding = true
	freeze = true
	if _light_tween:
		_light_tween.kill()
	bomb_light.light_energy = 0.0
	$AnimationPlayer.play("explode")
	$MeshInstance3D.visible = false
	var bodies_in_aoe = area.get_overlapping_bodies()
	for body in bodies_in_aoe:
		if body is Rock:
			if body.rock_data.is_destructible:
				body.destroy()
		elif body is Player:
			# raycast to player to allow hiding from explosion
			var space_state = get_world_3d().direct_space_state
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, body.global_position)
			query.collision_mask = 0b100111 # Layers 1, 2, 3, 6
			var result = space_state.intersect_ray(query)

			if result and result.collider == body:
				if body.has_node("IsKnockbacked"):
					var kb = body.get_node("IsKnockbacked") as IsKnockbacked
					kb.start(global_position)
				body.health.take_damage(damage)
		elif body.has_node("IsKnockbacked"):
			var kb = body.get_node("IsKnockbacked") as IsKnockbacked
			kb.start(global_position)

	await $AnimationPlayer.animation_finished
	exploded.emit()
	queue_free()

func _physics_process(delta: float) -> void:
	if _exploding:
		return
	_time_remaining -= delta
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		_flash_light()
		var t = clamp(1.0 - (_time_remaining / FUSE_DURATION), 0.0, 1.0)
		_flash_timer = lerp(0.6, 0.07, t)
