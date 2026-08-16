extends Button
class_name QuestListCard

signal selected(quest: QuestData)
var quest_data: QuestData

# Called when the node enters the scene tree for the first time.
func setup(_quest_data: QuestData) -> void:
	quest_data = _quest_data
	text = quest_data.title
	pressed.connect(_on_button_pressed)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_pressed():
	selected.emit(quest_data)
