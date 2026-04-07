extends Node

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_F11:
			var win := get_tree().root
			win.mode = Window.MODE_FULLSCREEN if win.mode != Window.MODE_FULLSCREEN else Window.MODE_WINDOWED
		KEY_F1:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
