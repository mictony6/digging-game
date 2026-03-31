class_name InventoryUI
extends Control

@export var player: CharacterBody3D

@onready var _grid: GridContainer = $Background/MarginContainer/HBox/LeftPanel/Scroll/Grid
@onready var _detail_icon: TextureRect = $Background/MarginContainer/HBox/RightPanel/VBox/Icon
@onready var _detail_name: Label = $Background/MarginContainer/HBox/RightPanel/VBox/ItemName
@onready var _detail_desc: Label = $Background/MarginContainer/HBox/RightPanel/VBox/Description
@onready var _detail_count: Label = $Background/MarginContainer/HBox/RightPanel/VBox/CountLabel
@onready var _sort_type_btn: Button = $Background/MarginContainer/HBox/LeftPanel/SortRow/SortByType
@onready var _sort_used_btn: Button = $Background/MarginContainer/HBox/LeftPanel/SortRow/SortByUsed
@onready var _crafting_row = $Background/MarginContainer/HBox/RightPanel/VBox/CraftingRow

const SLOT_SCENE := preload("res://ui/inventory/InventorySlotUI.tscn")
const TIMER_SCENE := preload("res://ui/inventory/CraftingTimerUI.tscn")

var _inventory
var _timer_widgets: Array = []

func _ready() -> void:
	hide()
	_sort_type_btn.pressed.connect(_on_sort_type)
	_sort_used_btn.pressed.connect(_on_sort_used)

func _build_crafting_timers() -> void:
	for child in _crafting_row.get_children():
		child.queue_free()
	_timer_widgets.clear()
	var managers := get_tree().get_nodes_in_group("crafting_manager")
	if managers.is_empty():
		return
	var cm := managers[0]
	for i in cm.recipe_count():
		var recipe = cm.recipes[i]
		var widget = TIMER_SCENE.instantiate()
		_crafting_row.add_child(widget)
		widget.setup(recipe.label, recipe.icon)
		_timer_widgets.append(widget)

func _process(_delta: float) -> void:
	if not visible:
		return
	var managers := get_tree().get_nodes_in_group("crafting_manager")
	if managers.is_empty():
		return
	var cm := managers[0]
	for i in _timer_widgets.size():
		if i >= cm.recipe_count():
			break
		var recipe = cm.recipes[i]
		var can: bool = cm.can_craft(recipe)
		var remaining: float = cm.timer_remaining(i)
		var widget = _timer_widgets[i]
		widget.progress = (1.0 - remaining / recipe.craft_interval) if can else 0.0
		widget.seconds_remaining = remaining if can else 0.0
		widget.grayed_out = not can

func open(inventory) -> void:
	_inventory = inventory
	_inventory.changed.connect(_refresh)
	_build_crafting_timers()
	_refresh()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	if _inventory and _inventory.changed.is_connected(_refresh):
		_inventory.changed.disconnect(_refresh)
	_clear_detail()
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	if _inventory == null:
		return
	for slot in _inventory.slots:
		var cell = SLOT_SCENE.instantiate()
		_grid.add_child(cell)
		cell.setup(slot)
		cell.hovered.connect(_on_slot_hovered)

func _on_slot_hovered(slot) -> void:
	if slot == null or slot.is_empty():
		_clear_detail()
		return
	_detail_icon.texture = slot.item.icon
	_detail_name.text = slot.item.name
	_detail_desc.text = slot.item.description
	_detail_count.text = "x%d" % slot.count

func _clear_detail() -> void:
	_detail_icon.texture = null
	_detail_name.text = ""
	_detail_desc.text = ""
	_detail_count.text = ""

func _on_sort_type() -> void:
	if _inventory:
		_inventory.sort_by_type()

func _on_sort_used() -> void:
	if _inventory:
		_inventory.sort_by_most_used()
