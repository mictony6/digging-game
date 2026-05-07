extends Node
class_name HasDrops

@export var drops: Array[DropData] = []
@export var pickup_scene: PackedScene

func spawn_drops(position: Vector3) -> void:
	if pickup_scene == null or drops.is_empty():
		return
	for drop: DropData in drops:
		if drop.item == null:
			continue
		var qty := randi_range(drop.min_qty, drop.max_qty)
		if qty <= 0:
			continue
		# for i in range(qty):
		var pickup: PickupItem = pickup_scene.instantiate()
		pickup.item_data = drop.item
		pickup.quantity = qty
		var offset := Vector3(randf_range(-0.2, 0.2), randf_range(0.1, 0.3), randf_range(-0.2, 0.2))
		pickup.set_pickup_spawn(position + offset)
		get_tree().current_scene.add_child(pickup)
