extends QuestReward
class_name UnlockQuestReward

@export var quest: QuestData


func give(_player: Player):
	QuestManager.unlock_quest(quest)
