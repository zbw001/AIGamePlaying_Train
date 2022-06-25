extends "on_ground.gd"

var state_id = 0

func update_animation():
	var animation_name = "idle"
	if not owner.active:
		animation_name = "sleep"
	if owner.main.is_over:
		animation_name = "smile"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	update_animation()
	.enter()

func update(_delta):
	var input_direction = get_input_direction()
	if owner.active and input_direction:
		emit_signal("finished", "move")
	.update(_delta)
