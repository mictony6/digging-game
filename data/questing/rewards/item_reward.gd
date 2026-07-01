extends QuestReward
class_name ItemReward
@export var item: ItemData
@export var amount: int = 1


func give(player: Player):
    player.inventory.add_item(item, amount)