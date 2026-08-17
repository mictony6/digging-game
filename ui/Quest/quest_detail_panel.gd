extends PanelContainer
class_name QuestDetailPanel
@onready var _quest_detail_title: Label = %QuestDetailTitle
@onready var _quest_detail_desc: Label = %QuestDetailDesc
@onready var _start_quest_button: Button = %QuestStartButton
@onready var _complete_quest_button: Button = %QuestCompleteButton
@onready var _objective_list: VBoxContainer = %ObjectivesList
var _quest: QuestData

func _ready() -> void:
	_start_quest_button.pressed.connect(_on_start_press)
	_complete_quest_button.pressed.connect(_on_complete_press)


func show_quest_detail(q: QuestData):
	_quest = q
	_quest_detail_desc.text = q.description
	_quest_detail_title.text = q.title

	for chck in _objective_list.get_children():
		chck.free()

	for obj in q.objectives:
		var checkbox: CheckBox = CheckBox.new()
		checkbox.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		checkbox.text = _parse_objective(obj)
		if obj.is_complete():
			checkbox.button_pressed = true
		_objective_list.add_child(checkbox)
		

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

func _on_complete_press():
	QuestManager.turn_in(_quest)
	_complete_quest_button.hide()

func _parse_objective(obj: QuestObjective):
	var action: String = QuestActions.Type.find_key(obj.action)
	action = action[0].to_upper() + action.substr(1).to_lower()

	var completion_amount: int = obj.amount
	var current_amount: int = obj.current
	var target_entity: String = TargetIds.stringify(obj.target)
	target_entity = target_entity.capitalize()
	if completion_amount > 1:
		target_entity += "s"


	return "%s %d %s - %d / %d" % [action, completion_amount, target_entity, current_amount, completion_amount]
