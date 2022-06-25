extends "in_air.gd"

var state_id = 4

func update_animation():
	var animation_name = "fall"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	var input_direction = get_input_direction()
	update_look_direction(input_direction)

	update_animation()
	


func update(delta):
	var input_direction = get_input_direction()
	update_look_direction(input_direction)

	if owner.position.y > Consts.LOWER_BOUND_HEIGHT:
		owner.hurt(owner.health, Vector2.ZERO)
	
	.update(delta)
