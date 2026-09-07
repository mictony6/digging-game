class_name SpikeRoller
extends RigidBody3D
var spin_speed: float = 3 * PI
var attack_damage: float = 15
var cool_down: float = 1.0
var cd_remaining_time: float = 1.0

func _ready() -> void:
	cd_remaining_time = cool_down
func _physics_process(delta: float) -> void:
	cd_remaining_time -= delta
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Spins strictly around the global Y-axis (upward axis)
	state.angular_velocity = Vector3.FORWARD * spin_speed

func _on_body_entered(body: Node) -> void:
	if cd_remaining_time > 0:
		return
	if body is Player:
		_deal_damage(body)
		cd_remaining_time = cool_down

func _deal_damage(player: Player):
	player.health.take_damage(attack_damage)
