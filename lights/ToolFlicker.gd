extends OmniLight3D
@export var enabled: bool
@export var max_energy: float = 0.1
@export var min_duration_to_on: float = 0.075
@export var max_duration_to_on: float = 0.1
@export var cooldown: float = 0.25
@export var start_delay: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	light_energy = max_energy
	if !enabled:
		light_energy = 0
		return
	if start_delay > 0:
		await get_tree().create_timer(start_delay).timeout
	var tween: Tween = create_tween()
	tween.set_loops()
	var dur = randf_range(min_duration_to_on, max_duration_to_on)
	tween.tween_property(self, "light_energy", max_energy, dur)
	tween.tween_property(self, "light_energy", 0, dur)
	await get_tree().create_timer(cooldown - (dur * 2)).timeout
