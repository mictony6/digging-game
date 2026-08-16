extends Button
class_name QuestListCard

@export var quest_data: QuestData


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if quest_data == null:
		return
	text = quest_data.title

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
