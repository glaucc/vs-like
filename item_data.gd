# ItemData.gd (Use this version to confirm)
extends Node

var ITEM_PATHS = [
	"res://resources/items/data/common_sword.tres",
	"res://resources/items/data/black_common_sword.tres",
]

var loaded_items: Dictionary = {}

func _ready() -> void:
	_load_all_item_resources()

func _load_all_item_resources() -> void:
	if ITEM_PATHS.is_empty():
		print("ItemData WARNING: No item paths defined in ITEM_PATHS array. Ensure paths are correct.")

	for path in ITEM_PATHS:
		print("ItemData DEBUG: Attempting to load: ", path)
		var item_resource_loaded: Resource = load(path)

		if item_resource_loaded:
			print("ItemData DEBUG: Resource loaded from ", path, ". Type: ", item_resource_loaded.get_class())
			var item_instance: Item = item_resource_loaded as Item

			if item_instance:
				print("ItemData DEBUG: Resource from ", path, " successfully cast to Item.")
				# Print the actual id value here
				print("ItemData DEBUG: item_instance.id value: '", item_instance.id, "' (Type: ", typeof(item_instance.id), ")")
				
				if typeof(item_instance.id) == TYPE_STRING: # Ensure id is a String
					if not item_instance.id.is_empty(): # This is the original problematic line
						loaded_items[item_instance.id] = item_instance
						print("ItemData: Loaded item: ", item_instance.id)
					else:
						print("ItemData ERROR: Item resource at path '", path, "' has an empty 'id'. Skipping.")
				else:
					print("ItemData ERROR: Item resource at path '", path, "' has 'id' but it's not a String. Type: ", typeof(item_instance.id), ". Skipping.")
			else:
				print("ItemData ERROR: Resource at path '", path, "' was loaded, but is NOT a valid 'Item' resource or could not be cast. Actual type: ", item_resource_loaded.get_class())
		else:
			print("ItemData ERROR: Failed to load Item resource from: ", path, ". Check path and if it's a valid Item resource.")
			
	if loaded_items.is_empty():
		print("ItemData WARNING: No item resources loaded. Ensure paths are correct and Item.tres files exist and extend 'Item'.")

func get_item_by_id(id: String) -> Item:
	if id.is_empty():
		return null
	if loaded_items.has(id):
		return loaded_items[id]
	else:
		print("ItemData ERROR: Item with ID '", id, "' not found in ItemData!")
		return null
