extends OmniLight3D
class_name ToolFlicker

@export var max_energy: float = 0.1
@export var attack: float = 0.02
@export var release: float = 0.15

var _tween: Tween

func flash() -> void:
	if _tween:
		_tween.kill()
	show()
	light_energy = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "light_energy", max_energy, attack)
	_tween.tween_property(self, "light_energy", 0.0, release)
