class_name ItemData
extends Resource

enum ItemType { MATERIAL, BOMB, TORCH }

@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MATERIAL
@export var max_stack: int = 99
