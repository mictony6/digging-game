extends QuestReward
class_name CoinsReward

@export var amount: int = 100


func give(player: Player):
	PlayerData.add_coins(amount)
