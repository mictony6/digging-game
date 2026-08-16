@tool
extends Resource
class_name QuestReward

enum RewardType {ITEM, COINS, DURABILITY, UNLOCK_QUEST}

@export var type: RewardType:
    set(value):
        type = value
        notify_property_list_changed() # rebuild inspector now

@export var amount: int = 1
@export var item: ItemData
@export var quest_id: String

func _validate_property(property: Dictionary) -> void:
    if property.name == "item" and type != RewardType.ITEM:
        property.usage = PROPERTY_USAGE_NO_EDITOR
    if property.name == "quest_id" and type != RewardType.UNLOCK_QUEST:
        property.usage = PROPERTY_USAGE_NO_EDITOR
    if property.name == "amount" and type == RewardType.UNLOCK_QUEST:
        property.usage = PROPERTY_USAGE_NO_EDITOR