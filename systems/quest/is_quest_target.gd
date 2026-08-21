extends Node
class_name IsQuestTarget

@export var action: QuestActions.Type
@export var target: TargetIds.Id
@export var amount: int = 1

signal quest_notified(action: QuestActions.Type, target: TargetIds.Id, amount: int)

func notify_quest(count: int = amount) -> void:
	QuestManager.notify(action, target, count)
	quest_notified.emit(action, target, count)
