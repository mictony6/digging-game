class_name ItemToast
extends PanelContainer

const FADE_IN  := 0.2
const HOLD     := 3.0
const FADE_OUT := 0.5

@onready var _icon: TextureRect = $HBoxContainer/Icon
@onready var _name_label: Label  = $HBoxContainer/VBox/NameLabel
@onready var _qty_label: Label   = $HBoxContainer/VBox/QtyLabel

var item_key: String = ""
var _qty: int = 0
var _tween: Tween


func setup(item_name: String, texture: Texture2D, qty: int = 1) -> void:
	item_key = item_name
	_icon.texture = texture
	_set_qty(qty)
	_start_lifecycle()


func accumulate(qty: int) -> void:
	_set_qty(_qty + qty)
	_start_lifecycle()


func dismiss() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT * 0.4)
	_tween.tween_callback(queue_free)


func _set_qty(qty: int) -> void:
	_qty = qty
	_name_label.text = item_key
	_qty_label.text = "×%d" % _qty if _qty > 1 else ""
	_qty_label.visible = _qty > 1


func _start_lifecycle() -> void:
	if _tween:
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(HOLD)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_callback(queue_free)
