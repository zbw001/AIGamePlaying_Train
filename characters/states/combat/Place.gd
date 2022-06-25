extends "res://scripts/state.gd"
# Collection of important methods to handle direction and animation.

var is_current = false

var last_animation = null

var state_id = 3

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	
func update_animation():
	var animation_name = "place"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	last_animation = owner.get_node("AnimatedSprite").animation
	update_animation()
	owner.look_direction = owner.action.action_args
	var block_ids = [23, 24, 25, 26, 27, 28]
	var map_location = owner.main.map.world_to_map(owner.main.map.to_local(owner.main.cur_character.get_node("..").to_global(owner.main.cur_character.position + owner.action.action_args)))
	if owner.main.map.get_cellv(map_location) == -1:
		owner.main.cursor_indicator.tile_map.mset_cellv(map_location, block_ids[rng.randi_range(0, len(block_ids) - 1)])
	else :
		print("放置操作被忽略！物品仍然消耗")
	owner.inventory.remove_item("simple_block", 1)
	owner.main.report(owner, "place", 0)
	is_current = true

func _on_AnimatedSprite_animation_finished():
	if is_current:
		emit_signal("finished", "previous")

func exit():
	is_current = false
	owner.get_node("AnimatedSprite").play(last_animation)

func check_action():
	pass
