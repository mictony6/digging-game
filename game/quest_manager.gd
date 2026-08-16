extends Node

signal quest_started(quest: QuestData)
signal quest_updated(quest: QuestData)
signal quest_turned_in(quest: QuestData)
signal flags_changed


const DATABASE: QuestDatabase = preload("res://data/questing/quest_database/QUEST_DATABASE.tres")

var active: Array[QuestData] = []
var completed: Array[StringName] = []
var flags: Dictionary = {} # current player flags "boss_killed" / "level_5_reached" -> true

var _monitored_quest_id: String = "" # quest the player last focused on, e.g. in the quest UI

func _ready() -> void:
	load_flags()

func start(data: QuestData) -> void:
	var quest_instance: QuestData = data.duplicate(true) # private copy — source stays clean
	active.append(quest_instance)
	quest_started.emit(quest_instance)

func notify(action: QuestActions.Type, target: TargetIds.Id, amount := 1) -> void:
	var quests_to_check: Array[QuestData] = active.duplicate() # a duplicate for iterations, changes are made on the active array

	for quest in quests_to_check:
		var touched := false

		for obj in quest.objectives:
			if not obj.is_complete() and obj.matches(action, target):
				obj.record(amount)
				touched = true

		if touched:
			quest_updated.emit(quest)
			# if quest.is_complete():
			# 	active.erase(quest)
			# 	_grant(quest)
			# 	quest_turned_in.emit(quest)
			# 	if quest.id == _monitored_quest_id:
			# 		set_monitored(null)

func get_active(id: String) -> QuestData:
	for q in active:
		if q.id == id:
			return q
	return null

func is_active(quest: QuestData):
	return active.any(func(a): return a.id == quest.id)


func _grant(quest: QuestData) -> void:
	for reward in quest.rewards:
		match reward.type:
			QuestReward.RewardType.ITEM:
				pass # TODO: Inventory.add(reward.item, reward.amount)
			QuestReward.RewardType.COINS:
				PlayerData.add_coins(reward.amount)
			QuestReward.RewardType.DURABILITY:
				pass # TODO: repair equipped tool by reward.amount
			QuestReward.RewardType.UNLOCK_QUEST:
				pass # TODO: QuestShop.unlock(reward.quest_id)


func _is_available(quest: QuestData):
	if quest.id in completed: return
	if active.any(func(a): return a.id == quest.id): return false # if its already active then ignore
	# check if it passes all flags
	for required_flag in quest.required_flags:
		if not flags.get(required_flag, false): return false
	return true


func set_flag(flag: StringName, value := true) -> void:
	flags[flag] = value
	flags_changed.emit()
	

func available_quest():
	var result: Array[QuestData] = []
	for quest in DATABASE.quests:
		if _is_available(quest):
			result.append(quest)
	return result


func load_flags(path := "res://save/slot01/progress.json") -> void:
	if not FileAccess.file_exists(path):
		push_warning("No file at " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if data == null:
		push_warning("Bad JSON in " + path) # usually a trailing comma or stray quote
		return

	flags = data.get("flags", {})
	print("Loaded flags: ", QuestManager.flags)

func set_monitored(quest: QuestData):
	if quest != null:
		_monitored_quest_id = quest.id
	else:
		_monitored_quest_id = ""

func get_monitored() -> QuestData:
	var monitored := active.filter(func(a): return a.id == _monitored_quest_id)
	if monitored.size() > 0:
		return monitored[0]

	for quest in available_quest():
		if quest.id == _monitored_quest_id:
			return quest

	if active.size() > 0:
		return active[0]

	var avail: Array[QuestData] = available_quest()
	if avail.size() > 0:
		return avail[0]

	return null


func turn_in(quest: QuestData) -> void:
	if not quest.is_complete() or not active.has(quest):
		return
	active.erase(quest)
	completed.append(quest.id)
	_grant(quest)
	quest_turned_in.emit(quest)
	if quest.id == _monitored_quest_id:
		set_monitored(null)
