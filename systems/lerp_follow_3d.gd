class_name LerpFollow3D
extends Node

enum FollowMode {NONE, SNAP, LERP, PREDICT}

@export var parent_node: Node3D
@export var child_node: Node3D
@export var lerp_speed := 8.0
@export var position_mode: FollowMode = FollowMode.LERP
@export var rotation_mode: FollowMode = FollowMode.LERP

@export_group("Predict Mode")
@export var lead_time := 0.15 # seconds to project ahead
@export var velocity_smoothing := 10.0 # higher = less jitter, more lag on the prediction itself

var _prev_pos: Vector3
var _prev_basis: Basis
var _smoothed_lin_vel := Vector3.ZERO
var _smoothed_ang_vel := Vector3.ZERO
var _initialized := false

func _ready():
    if child_node:
        child_node.top_level = true

func _process(delta):
    if not parent_node or not child_node or delta <= 0.0:
        return

    var parent_xform = parent_node.global_transform
    var t = child_node.global_transform

    if not _initialized:
        _prev_pos = parent_xform.origin
        _prev_basis = parent_xform.basis
        _initialized = true

    # --- smoothed velocity estimate ---
    var raw_lin_vel = (parent_xform.origin - _prev_pos) / delta
    _smoothed_lin_vel = _smoothed_lin_vel.lerp(raw_lin_vel, clamp(velocity_smoothing * delta, 0.0, 1.0))

    var dq = Quaternion(parent_xform.basis) * Quaternion(_prev_basis).inverse()
    var raw_ang_vel = dq.get_axis() * dq.get_angle() / delta
    _smoothed_ang_vel = _smoothed_ang_vel.lerp(raw_ang_vel, clamp(velocity_smoothing * delta, 0.0, 1.0))

    _prev_pos = parent_xform.origin
    _prev_basis = parent_xform.basis

    # --- position ---
    match position_mode:
        FollowMode.SNAP:
            t.origin = parent_xform.origin
        FollowMode.LERP:
            t.origin = t.origin.lerp(parent_xform.origin, lerp_speed * delta)
        FollowMode.PREDICT:
            var lead_pos = parent_xform.origin + _smoothed_lin_vel * lead_time
            t.origin = t.origin.lerp(lead_pos, lerp_speed * delta)

    # --- rotation ---
    match rotation_mode:
        FollowMode.SNAP:
            t.basis = parent_xform.basis
        FollowMode.LERP:
            t.basis = t.basis.slerp(parent_xform.basis, lerp_speed * delta)
        FollowMode.PREDICT:
            var lead_basis = parent_xform.basis
            if _smoothed_ang_vel.length() > 0.0001:
                var extra = Basis(_smoothed_ang_vel.normalized(), _smoothed_ang_vel.length() * lead_time)
                lead_basis = extra * parent_xform.basis
            t.basis = t.basis.slerp(lead_basis, lerp_speed * delta)

    child_node.global_transform = t