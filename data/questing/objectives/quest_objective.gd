extends Resource
class_name QuestObjective


@export var action: QuestActions.Type
@export var target: TargetIds.Id
@export var amount: int = 1

var current: int = 0 # runtime progress — lives on the duplicated copy, not the source .tres

func matches(a: QuestActions.Type, t: TargetIds.Id) -> bool:
	return action == a and target == t

func record(n: int) -> void:
	current = min(current + n, amount)

func is_complete() -> bool:
	return current >= amount