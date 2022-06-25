extends "on_ground.gd"

var state_id = 1

var max_walk_speed = Consts.WALK_SPEED

func update_animation():
	var animation_name = "walk"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	var input_direction = get_input_direction()
	update_look_direction(input_direction)
	update_animation()
	.enter()

func update(_delta):
	var input_direction = get_input_direction()
	if not owner.active or not input_direction:
		emit_signal("finished", "idle")
	update_look_direction(input_direction)
	
	if owner.active:
		owner._velocity = input_direction.normalized() * max_walk_speed * _delta
		owner.main.report(owner, "move", _delta)
	
	.update(_delta)
