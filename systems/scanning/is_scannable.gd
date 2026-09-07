extends Node
class_name IsScannable

@export_multiline var scan_text: String = ""
@export var reveal_once: bool = true
var revealed_flag: bool = false

signal revealed(text: String)

func reveal() -> void:
	if reveal_once and revealed_flag:
		return
	revealed_flag = true
	revealed.emit(scan_text)
