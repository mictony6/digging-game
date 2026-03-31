class_name CraftingManager
extends Node

@export var player_inventory: HasInventory
@export var recipes: Array[CraftingRecipe] = [] # Array of CraftingRecipe

var _timers: Array[float] = []

func _ready() -> void:
	add_to_group("crafting_manager")
	_timers.resize(recipes.size())
	_timers.fill(0.0)

func _process(delta: float) -> void:
	if player_inventory == null:
		return
	for i in recipes.size():
		var recipe = recipes[i] as CraftingRecipe
		if can_craft(recipe):
			_timers[i] += delta
			if _timers[i] >= recipe.craft_interval:
				_timers[i] = 0.0
				_do_craft(recipe)
		else:
			_timers[i] = 0.0

func can_craft(recipe: CraftingRecipe) -> bool:
	if player_inventory == null:
		return false
	if recipe.ingredient_items.is_empty():
		return false
	if player_inventory.get_count(recipe.output_item) >= recipe.output_item.max_stack:
		return false
	for i in recipe.ingredient_items.size():
		var amount: int = recipe.ingredient_amounts[i] if i < recipe.ingredient_amounts.size() else 1
		if not player_inventory.has_items(recipe.ingredient_items[i], amount):
			return false
	return true

func _do_craft(recipe: CraftingRecipe) -> void:
	if not can_craft(recipe):
		return
	for i in recipe.ingredient_items.size():
		var amount: int = recipe.ingredient_amounts[i] if i < recipe.ingredient_amounts.size() else 1
		player_inventory.remove_item(recipe.ingredient_items[i], amount)
	var current := player_inventory.get_count(recipe.output_item)
	var to_add := mini(recipe.output_amount, recipe.output_item.max_stack - current)
	player_inventory.add_item(recipe.output_item, to_add)

func timer_remaining(index: int) -> float:
	if index >= _timers.size() or index >= recipes.size():
		return 0.0
	return recipes[index].craft_interval - _timers[index]

func recipe_count() -> int:
	return recipes.size()
