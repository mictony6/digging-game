extends Control

@onready var start_btn: Button = %StartButton
@onready var load_btn: Button = %LoadButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = $%QuitButton

signal start_pressed
signal load_pressed
signal settings_pressed
signal quit_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	start_btn.pressed.connect(func(): start_pressed.emit())
	load_btn.pressed.connect(func(): load_pressed.emit())
	settings_btn.pressed.connect(func(): settings_pressed.emit())
	quit_btn.pressed.connect(func(): quit_pressed.emit())
