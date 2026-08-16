extends PanelContainer
class_name QuestDetailPanel
@onready var _quest_detail_title: Label = %QuestDetailTitle
@onready var _quest_detail_desc: Label = %QuestDetailDesc
@onready var _start_quest_button: Button = %QuestStartButton
@onready var _complete_quest_button: Button = %QuestCompleteButton
var _quest: QuestData

func _ready() -> void:
	_start_quest_button.pressed.connect(_on_start_press)

func show_quest_detail(q: QuestData):
	_quest = q
	_quest_detail_desc.text = q.description
	_quest_detail_title.text = q.title

	if q.is_complete():
		_start_quest_button.hide()
		_complete_quest_button.show()
	elif !QuestManager.is_active(q):
		_start_quest_button.show()
		_complete_quest_button.hide()
	else:
		_start_quest_button.hide()
		_complete_quest_button.hide()

	
func _on_start_press():
	QuestManager.start(_quest)
	_start_quest_button.hide()
