extends Control
## Standalone scene for exercising QuestManager without loading the full game.
## Run this scene directly (F6) — QuestManager is an autoload so it works in isolation.

@onready var _log: RichTextLabel = %Log
@onready var _flags_box: VBoxContainer = %FlagsBox
@onready var _available_box: VBoxContainer = %AvailableBox
@onready var _active_box: VBoxContainer = %ActiveBox
@onready var _completed_box: VBoxContainer = %CompletedBox
@onready var _flag_name_edit: LineEdit = %FlagNameEdit


func _ready() -> void:
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_updated.connect(_on_quest_updated)
	QuestManager.quest_turned_in.connect(_on_quest_turned_in)
	QuestManager.flags_changed.connect(_on_flags_changed)

	%AddFlagButton.pressed.connect(_on_add_flag_pressed)
	%ClearLogButton.pressed.connect(func(): _log.clear())

	_log_line("[color=gray]Sandbox ready. QuestManager has %d quest(s) in database.[/color]" % QuestManager.DATABASE.quests.size())
	_refresh_all()


func _refresh_all() -> void:
	_refresh_flags()
	_refresh_available()
	_refresh_active()
	_refresh_completed()


func _refresh_flags() -> void:
	for c in _flags_box.get_children():
		c.free()

	var known_flags: Array = []
	for quest in QuestManager.DATABASE.quests:
		for flag in quest.required_flags:
			if not known_flags.has(flag):
				known_flags.append(flag)
	for flag in QuestManager.flags.keys():
		if not known_flags.has(flag):
			known_flags.append(flag)

	for flag in known_flags:
		var row := HBoxContainer.new()
		var check := CheckBox.new()
		check.text = str(flag)
		check.button_pressed = QuestManager.flags.get(flag, false)
		check.toggled.connect(func(v): QuestManager.set_flag(flag, v))
		row.add_child(check)
		_flags_box.add_child(row)


func _refresh_available() -> void:
	for c in _available_box.get_children():
		c.free()

	for quest in QuestManager.available_quest():
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = quest.title
		label.custom_minimum_size.x = 220
		row.add_child(label)

		var start_btn := Button.new()
		start_btn.text = "Start"
		start_btn.pressed.connect(func(): QuestManager.start(quest))
		row.add_child(start_btn)

		_available_box.add_child(row)


func _refresh_active() -> void:
	for c in _active_box.get_children():
		c.free()

	for quest in QuestManager.active:
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)

		var title := Label.new()
		title.text = quest.title
		vbox.add_child(title)

		for obj in quest.objectives:
			var row := HBoxContainer.new()

			var obj_label := Label.new()
			var action_name: String = QuestActions.stringify(obj.action)
			var target_name: String = TargetIds.stringify(obj.target)
			obj_label.text = "%s %s: %d / %d" % [action_name, target_name, obj.current, obj.amount]
			obj_label.custom_minimum_size.x = 220
			row.add_child(obj_label)

			var progress_btn := Button.new()
			progress_btn.text = "+1 progress"
			progress_btn.disabled = obj.is_complete()
			progress_btn.pressed.connect(func(): QuestManager.notify(obj.action, obj.target, 1))
			row.add_child(progress_btn)

			vbox.add_child(row)

		var turn_in_btn := Button.new()
		turn_in_btn.text = "Turn In"
		turn_in_btn.disabled = not quest.is_complete()
		turn_in_btn.pressed.connect(func(): QuestManager.turn_in(quest))
		vbox.add_child(turn_in_btn)

		_active_box.add_child(panel)


func _refresh_completed() -> void:
	for c in _completed_box.get_children():
		c.free()

	for id in QuestManager.completed:
		var label := Label.new()
		label.text = str(id)
		_completed_box.add_child(label)


func _on_add_flag_pressed() -> void:
	var flag_name := _flag_name_edit.text.strip_edges()
	if flag_name.is_empty():
		return
	QuestManager.set_flag(StringName(flag_name), true)
	_flag_name_edit.text = ""


func _on_quest_started(quest: QuestData) -> void:
	_log_line("[color=lightgreen]quest_started[/color]: %s" % quest.title)
	_refresh_all()


func _on_quest_updated(quest: QuestData) -> void:
	_log_line("[color=yellow]quest_updated[/color]: %s" % quest.title)
	_refresh_all()


func _on_quest_turned_in(quest: QuestData) -> void:
	_log_line("[color=orange]quest_turned_in[/color]: %s" % quest.title)
	_refresh_all()


func _on_flags_changed() -> void:
	_log_line("[color=cyan]flags_changed[/color]: %s" % str(QuestManager.flags))
	_refresh_all()


func _log_line(text: String) -> void:
	if _log:
		_log.append_text(text + "\n")
