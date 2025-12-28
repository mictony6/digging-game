extends Area3D
class_name IsSelectable

@export var can_be_selected: bool = true
@export var interaction_name: String
@export var secondary_interaction_name: String
var interaction_index: int = 0


@export var target_mesh: MeshInstance3D
@export var outline_material: Material
@onready var prompt: Control = $Prompt
var label: Label

# for some reason i made this a callable. this cold be a signal instead where items can connect to. but this is fine for now
# var select: Callable = (func(): pass )
# i did this hehe and even made the stupid unused signal go away. im a great programmer 
signal selected
signal hovered
signal unhovered

func _ready() -> void:
	label = prompt.get_node("HSplitContainer/Label")
	label.text = interaction_name
	prompt.hide()
	add_to_group("Selectable")

func _process(delta: float) -> void:
	if is_visible_in_tree() and can_be_selected:
		var camera = get_viewport().get_camera_3d()
		if camera.is_position_behind(global_position):
			unhover()
			return

		var screen_position = camera.unproject_position(global_position)
		screen_position.x += prompt.size.x
		# screen_position.y -= input_prompt.size.y

		prompt.global_position = screen_position
	else:
		unhover()
func hover() -> void:
	if !can_be_selected:
		return
	prompt.show()
	target_mesh.material_overlay = outline_material
	hovered.emit()

func unhover() -> void:
	prompt.hide()
	target_mesh.material_overlay = null
	unhovered.emit()

func switch_interaction_label() -> void:
	if interaction_index == 0:
		label.text = secondary_interaction_name
		interaction_index = 1
	else:
		label.text = interaction_name
		interaction_index = 0

func select():
	selected.emit()
