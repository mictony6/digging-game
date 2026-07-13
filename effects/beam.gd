class_name LaserBeam
extends Node3D

## Seconds for the beam to extend from the tool tip to the target when shown.
@export var grow_time: float = 0.08

@onready var _mesh: MeshInstance3D = $BeamMesh
@onready var _halo: MeshInstance3D = $ImpactHalo
@onready var _flames: GPUParticles3D = $ImpactFlames

var _length: float = 1.0
var _progress: float = 0.0

## Stretches the beam to reach a global-space target. The node itself is NOT
## rotated: the beam launches along this node's -Z (the emitter's direction)
## and the shader curves it over to the target.
## Call every physics frame while the beam is visible.
func aim(target: Vector3, normal: Vector3 = Vector3.ZERO) -> void:
	# The beam terminates slightly off the surface, and the halo and flames
	# are centered on that same point — so the tip and halo always connect,
	# and the halo billboard doesn't clip into the surface.
	var end := target + (normal * 0.03 if normal != Vector3.ZERO else Vector3.ZERO)
	var local_target := to_local(end)
	_length = local_target.length()
	if _length < 0.001:
		return
	_mesh.set_instance_shader_parameter("target_local", local_target)
	_mesh.set_instance_shader_parameter("beam_length", _length)
	_halo.global_position = end
	_flames.global_position = end

func _process(delta: float) -> void:
	if not visible:
		return
	_progress = move_toward(_progress, 1.0, delta / maxf(grow_time, 0.001))
	_mesh.set_instance_shader_parameter("progress", _progress)

func _on_visibility_changed() -> void:
	if _mesh == null:
		return
	if _flames:
		_flames.emitting = is_visible_in_tree()
	if is_visible_in_tree():
		_progress = 0.0
		_mesh.set_instance_shader_parameter("progress", 0.0)
