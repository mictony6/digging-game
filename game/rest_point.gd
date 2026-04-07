extends StaticBody3D

# Attach this to a bed/tent/exit gate in the surface area.
# Wire IsSelectable.selected -> _on_is_selectable_selected in the Inspector.

func _on_is_selectable_selected(_player: Player, _tool) -> void:
	print("day end")
	DateManager.end_day()
