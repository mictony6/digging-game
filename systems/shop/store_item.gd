extends PanelContainer
class_name StoreItem

signal purchase_requested(item: ItemData, cost: int)

@export var item: ItemData
@export var cost: int = 10

@onready var _icon: TextureRect = $Margin/VBoxContainer/TextureRect
@onready var _name_label: Label = $Margin/VBoxContainer/Label
@onready var _buy_button: Button = $Margin/VBoxContainer/Button

func _ready() -> void:
	_buy_button.pressed.connect(_on_buy_pressed)
	_refresh()

func set_item(p_item: ItemData, p_cost: int) -> void:
	item = p_item
	cost = p_cost
	_refresh()

func _refresh() -> void:
	if item == null:
		return
	_name_label.text = item.name
	_icon.texture = item.icon
	_buy_button.text = "Buy  %d coins" % cost

func _on_buy_pressed() -> void:
	if item == null:
		return
	purchase_requested.emit(item, cost)
