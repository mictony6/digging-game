extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_and_exit()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_is_selectable_selected() -> void:
	show_ui()
	

func _on_exit_button_pressed() -> void:
	hide_and_exit()

func hide_and_exit():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false

func show_ui():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	visible = true
