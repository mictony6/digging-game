extends OmniLight3D
@export var enabled: bool
var max_energy: float = 0.1
var min_duration_to_on: float = 0.075
var max_duration_to_on: float = 0.1
var cooldown: float = 0.25

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !enabled:
		light_energy = 0
		return
	hide()
	var tween: Tween = get_tree().create_tween()
	tween.set_loops()
	var dur = randf_range(min_duration_to_on, max_duration_to_on)
	tween.tween_property(self, "light_energy", max_energy, dur)
	tween.tween_property(self, "light_energy", 0, dur)
	await get_tree().create_timer(cooldown - (dur * 2)).timeout