class_name QuestActions
enum Type {
	KILL,
	COLLECT,
	REACH,
	TALK,
	MINE,
}

const NAMES := [
	"Kill",
	"Collect",
	"Reach",
	"Talk",
	"Mine",
]

static func stringify(id: QuestActions.Type) -> String:
	return NAMES[id]
