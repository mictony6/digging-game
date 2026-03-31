class_name CraftingRecipe
extends Resource

@export var label: String = ""
@export var icon: Texture2D
@export var output_item: ItemData
@export var output_amount: int = 1
@export var craft_interval: float = 15.0
## One entry per ingredient — must match ingredient_amounts by index
@export var ingredient_items: Array[ItemData] = [] # Array of ItemData
## One amount per ingredient — must match ingredient_items by index
@export var ingredient_amounts: Array[int] = []
