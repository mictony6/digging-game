extends VBoxContainer

@export var arc_color: Color = Color(0.4, 0.8, 0.4, 1)

var progress: float = 0.0
var seconds_remaining: float = 0.0
var grayed_out: bool = false

@onready var _bar: TextureProgressBar = $Bar
@onready var _icon: TextureRect = $Bar/Icon
@onready var _time_label: Label = $Bar/TimeLabel
@onready var _name_label: Label = $NameLabel

func _process(_delta: float) -> void:
	_bar.value = progress * 100
	_bar.tint_progress = arc_color if not grayed_out else Color(0.4, 0.4, 0.4, 1.0)
	_time_label.text = "%ds" % int(ceil(seconds_remaining)) if seconds_remaining > 0 else ""

func setup(label: String, icon: Texture2D) -> void:
	_name_label.text = label
	_icon.texture = icon
