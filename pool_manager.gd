extends Node

var mob_pools := {}

func register_pool(group_name: String, scene: PackedScene):
	mob_pools[group_name] = ObjectPool.new(scene)


func get_from_pool(group_name: String) -> Node:
	if mob_pools.has(group_name):
		return mob_pools[group_name].get_instance()
	return null


func return_to_pool(group_name: String, mob: Node):
	if mob_pools.has(group_name):
		mob_pools[group_name].free_instance(mob)


func _ready():
	#Mobs
	register_pool("mob", preload("res://mob.tscn"))
	register_pool("python", preload("res://python.tscn"))
	register_pool("pyscho", preload("res://psycho.tscn"))
	register_pool("bat", preload("res://bat.tscn"))
	
	#Bosses
	register_pool("boss1", preload("res://boss_10.tscn"))
	register_pool("bull_boss", preload("res://bull-boss10.tscn"))
	register_pool("giant_boss", preload("res://giant-boss-20.tscn"))
