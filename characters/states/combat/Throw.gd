extends "res://scripts/state.gd"
# Collection of important methods to handle direction and animation.


var state_id = 7

var is_current = false

var last_animation = null

func update_animation():
	var animation_name = "throw"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	last_animation = owner.get_node("AnimatedSprite").animation
	update_animation()
	owner.look_direction = owner.action.action_args
	owner.main.map.add_bomb(owner.main.cur_character.position, owner.action.action_args, owner)
	owner.inventory.remove_item("bomb", 1)
	owner.main.report(owner, "throw", 0)
	is_current = true

func _on_AnimatedSprite_animation_finished():
	if is_current:
		emit_signal("finished", "previous")

func exit():
	is_current = false
	owner.get_node("AnimatedSprite").play(last_animation)

func check_action():
	pass
