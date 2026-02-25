extends State
class_name TurretState

const IDLE = "Idle";
const ALERT = "Alert";
const LOCKED_IN = "LockedIn";
const ATTACKING = "Attacking";
const COOL_DOWN = "CoolDown";


var turret: Turret;
var head: AnimatableBody3D

func _ready() -> void:
	await owner.ready;
	turret = owner as Turret;
	head = turret.head
	assert(turret != null, "The TurretState state type must be used only in the turret scene. It needs the owner to be a Turret node.");
