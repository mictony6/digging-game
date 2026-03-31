class_name InventorySlotUI
extends PanelContainer

signal hovered(slot)

var slot

@onready var _icon: TextureRect = $VBoxContainer/Icon
@onready var _count_label: Label = $VBoxContainer/CountLabel

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)

func setup(p_slot) -> void:
	slot = p_slot
	_refresh()

func _refresh() -> void:
	if slot == null or slot.is_empty():
		_icon.texture = null
		_count_label.text = ""
		return
	_icon.texture = slot.item.icon
	_count_label.text = str(slot.count) if slot.count > 1 else ""

func _on_mouse_entered() -> void:
	hovered.emit(slot)
