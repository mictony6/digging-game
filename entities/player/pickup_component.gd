extends Node
class_name PickupComponent

@export var pickup_radius: float = 2.5
const HOLD_PICKUP_TIME := 0.4

signal item_collected(item: Resource, qty: int)

var _hold_pickup_timer: float = 0.0
var _holding_pickup: bool = false

func process_input(delta: float) -> void:
	if Input.is_action_pressed("pickup"):
		if not _holding_pickup:
			_hold_pickup_timer += delta
			if _hold_pickup_timer >= HOLD_PICKUP_TIME:
				_holding_pickup = true
				_pickup_all_in_range()
	else:
		if not _holding_pickup and _hold_pickup_timer > 0.0:
			_pickup_nearest()
		_hold_pickup_timer = 0.0
		_holding_pickup = false

func reset() -> void:
	_holding_pickup = false
	_hold_pickup_timer = 0.0

func _get_nearby_pickups() -> Array:
	var result: Array = []
	var pos: Vector3 = get_parent().global_position
	for node in get_tree().get_nodes_in_group("pickups"):
		if node is PickupItem and node.global_position.distance_to(pos) <= pickup_radius:
			result.append(node)
	return result

func _pickup_nearest() -> void:
	var nearby := _get_nearby_pickups()
	if nearby.is_empty():
		return
	var pos: Vector3 = get_parent().global_position
	var closest = nearby[0]
	var closest_dist: float = closest.global_position.distance_to(pos)
	for item in nearby:
		var d: float = item.global_position.distance_to(pos)
		if d < closest_dist:
			closest = item
			closest_dist = d
	_collect(closest)

func _pickup_all_in_range() -> void:
	for item in _get_nearby_pickups():
		_collect(item)

func _collect(pickup: PickupItem) -> void:
	if pickup._attracting:
		return
	pickup.picked_up.connect(func(item, qty): item_collected.emit(item, qty))
	pickup.attract_to(get_parent())
