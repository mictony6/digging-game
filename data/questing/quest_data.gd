extends Resource
class_name QuestData

@export var id: String
@export var title: String
@export var description: String
@export var objectives: Array[QuestObjective]
@export var rewards: Array[QuestReward]

@export var required_flags: Array[StringName] = [] # events that must have fired

func is_complete() -> bool:
	return objectives.all(func(o): return o.is_complete())
