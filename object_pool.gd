extends Node

class_name ObjectPool

var scene:PackedScene
var pool: Array = []

func _init(_scene: PackedScene) -> void:
	scene = _scene


func get_instance() -> Node:
	if pool.size() > 0:
		var inst = pool.pop_back()
		inst.visible = true
		return inst
	else:
		return scene.instantiate()


func free_instance(node: Node):
	node.visible = false
	node.get_parent().remove_child(node)
	pool.append(node)
