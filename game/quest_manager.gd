extends Node

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	FAILED
}

func unlock_quest(quest: QuestData):
	quest.state = QuestManager.QuestState.ACTIVE