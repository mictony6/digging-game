extends Node3D
var tween: Tween
var fade_in_progress: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		if tween:
			tween.kill()
		
		tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_parallel(true) # Update all meshes simultaneously
		
		# Update each mesh's shader parameter directly via tween
		for i in range(1, get_child_count()):
			var mesh = get_child(i) as MeshInstance3D
			if mesh and mesh.material_override:
				# Set initial value
				mesh.material_override.set_shader_parameter("fade_progress", 0.0)
				# Tween to final value
				tween.tween_method(
					func(value): mesh.material_override.set_shader_parameter("fade_progress", value),
					0.0,
					1.0,
					0.25
				)