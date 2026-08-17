class_name TargetIds
enum Id {
	ROCK_EASY,
	ROCK_MEDIUM,
	ROCK_HARD,
	ROCK_PRISTINE,
	ROCK_EPIC,
}

const NAMES := [
	"Stone",
	"Iron",
	"Gold",
	"Diamond",
	"Meteorite",
]

static func stringify(id: TargetIds.Id) -> String:
	return NAMES[id]