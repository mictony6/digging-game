extends Resource
class_name QuestData


@export var id: String
@export var title: String
@export var description: String
@export var state: QuestManager.QuestState
@export var rewards: Array[QuestReward]