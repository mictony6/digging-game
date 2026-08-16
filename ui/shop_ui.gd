extends Control
class_name ShopUI

signal closed

const STORE_ITEM_SCENE := preload("res://systems/shop/store_item.tscn")
const UPGRADE_SCENE := preload("res://ui/UpgradeItem.tscn")
const QUEST_LIST_CARD_SCENE: PackedScene = preload("res://ui/Quest/quest_list_card.tscn")

@onready var _blur_rect: ColorRect = $BlurRect
@onready var _exit_button: Button = %ExitButton
@onready var _upgrade_parent: VBoxContainer = %UpgradeParent
@onready var _store_grid: GridContainer = $Panel/OuterVBox/ContentMargin/TabContainer/Buy/StoreItemGrid
@onready var _add_coins_button: Button = $Panel/OuterVBox/ContentMargin/TabContainer/Sell/Add100Coins
@onready var _available_quest_list: VBoxContainer = %AvailableQuests
@onready var _active_quest_list: VBoxContainer = %ActiveQuests
@onready var _quest_scroll: SmoothScrollContainer = %QuestScrollPanel
@onready var _quest_detail_panel: QuestDetailPanel = %QuestDetailPanel
var _upgrades: Array[UpgradeItem] = []
var _store_items: Array[StoreItem] = []
var _inventory: Inventory

func _ready() -> void:
	add_to_group("shop_ui")
	_exit_button.pressed.connect(_on_exit_pressed)
	_add_coins_button.pressed.connect(func(): PlayerData.add_coins(100))
	QuestManager.quest_started.connect(_on_quest_list_changed)
	QuestManager.quest_completed.connect(_on_quest_list_changed)
	hide()

func open(player: Player, current_tool: Tool, tool_manager: ToolManager,
		items: Array, upgrades: Array) -> void:
	_inventory = player.inventory.get_inventory()
	_populate_store(items)
	_populate_upgrades(upgrades, current_tool, tool_manager)
	_refresh_quest_list()

	_blur_rect.modulate.a = 0.0
	show()
	var t := create_tween()
	t.tween_property(_blur_rect, "modulate:a", 1.0, 0.18)


func _populate_store(items: Array) -> void:
	for child in _store_grid.get_children():
		child.queue_free()
	_store_items.clear()
	for entry in items:
		var widget: StoreItem = STORE_ITEM_SCENE.instantiate()
		_store_grid.add_child(widget)
		widget.set_item(entry.item, entry.cost)
		widget.purchase_requested.connect(_on_purchase_requested)
		_store_items.append(widget)

func _populate_upgrades(upgrades: Array, current_tool: Tool, tool_manager: ToolManager) -> void:
	for child in _upgrade_parent.get_children():
		child.queue_free()
	_upgrades.clear()
	for entry in upgrades:
		var widget: UpgradeItem = UPGRADE_SCENE.instantiate()
		widget.upgrade = entry.upgrade_type
		widget.cost = entry.base_cost
		widget.cost_multiplier = entry.cost_multiplier
		_upgrade_parent.add_child(widget)
		widget.set_tool(current_tool, tool_manager)
		_upgrades.append(widget)


func _on_quest_list_changed(_quest: QuestData) -> void:
	if not visible:
		return
	_refresh_quest_list()

func _refresh_quest_list() -> void:
	_populate_quest_list(QuestManager.active, QuestManager.available_quest())

	var monitored_quest: QuestData = QuestManager.get_monitored()
	if monitored_quest != null:
		var card := _find_quest_card(monitored_quest.id)
		if card != null:
			card.button_pressed = true
			_scroll_to_card(card)
		_on_quest_card_selected(monitored_quest)

func _populate_quest_list(active_quests: Array[QuestData], available_quests: Array[QuestData]):
	#popoulate active quests
	for child in _active_quest_list.get_children():
		child.free()
	for quest in active_quests:
		if quest.is_complete():
			continue
		_make_card(quest, _active_quest_list)

	#populate available quests
	for child in _available_quest_list.get_children():
		child.free()
	for quest in available_quests:
		if quest.is_complete():
			continue
		_make_card(quest, _available_quest_list)
		

func close() -> void:
	hide()
	closed.emit()

func _on_exit_pressed() -> void:
	close()

func _on_purchase_requested(item: ItemData, cost: int) -> void:
	if _inventory == null or PlayerData.coins < cost:
		return
	PlayerData.remove_coins(cost)
	_inventory.add_item(item)


func _make_card(quest: QuestData, list: VBoxContainer) -> void:
	var card: QuestListCard = QUEST_LIST_CARD_SCENE.instantiate()
	list.add_child(card)
	card.setup(quest)
	card.selected.connect(_on_quest_card_selected)

func _on_quest_card_selected(quest: QuestData):
	_quest_detail_panel.show_quest_detail(quest)
	QuestManager.set_monitored(quest)

func _find_quest_card(id: String) -> QuestListCard:
	for child in _active_quest_list.get_children() + _available_quest_list.get_children():
		if child is QuestListCard and child.quest_data.id == id:
			return child
	return null

func _scroll_to_card(card: QuestListCard) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	if not is_instance_valid(card):
		return

	_quest_scroll.ensure_control_visible_smooth(card)
