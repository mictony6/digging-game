@abstract
extends Resource
class_name QuestReward


enum RewardType {
    ITEM,
    COINS,
    DURABILITY,
    UNLOCK_QUEST,

}

@export var reward_type: RewardType

@abstract
func give(player: Player)
