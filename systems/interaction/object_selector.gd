extends RayCast3D

var last_selectable: IsSelectable
@export var _player: Player
@export var _tool: Tool

func _ready():
	assert(_player != null or _tool != null, "Player pr tool should be set in the object selector")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if is_colliding() and get_collider().is_in_group("Selectable"):
		var colliding_body: IsSelectable = get_collider()
		colliding_body.hover()

		#remove highlight from last object that was hovered
		if last_selectable and last_selectable != colliding_body:
			last_selectable.unhover()

		last_selectable = colliding_body
	else:
		if last_selectable:
			last_selectable.unhover()
			last_selectable = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if last_selectable and last_selectable.can_be_selected:
				last_selectable.select(_player, _tool)
