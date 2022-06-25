extends "in_air.gd"

var state_id = 2

export(float) var v0 = 600

func update_animation():
	var animation_name = "jump"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	var input_direction = get_input_direction()
	update_look_direction(input_direction)

	update_animation()
	owner._velocity.y = -v0
	
	owner.main.report(owner, "jump", 0)


func update(delta):
	var input_direction = get_input_direction()
	update_look_direction(input_direction)
	
	if owner._velocity.y >= 0.0:
		emit_signal("finished", "fall")
	
	.update(delta)
