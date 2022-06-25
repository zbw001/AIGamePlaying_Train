extends "res://scripts/state.gd"

var state_id = 5

signal stopped
var gravity = Consts.GRAVITY

func update_animation():
	var animation_name = "die"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	owner.set_dead(true)
	update_animation()

func update(_delta):
	owner._velocity.y += gravity * _delta
	owner._velocity = owner.move_and_slide(owner._velocity, Vector2.UP, false, 4, 0.785398, false)
	if owner.is_on_floor():
		if owner._velocity.x > 0:
			owner._velocity.x = max(0, owner._velocity.x - _delta * Consts.FRICTION)
		if owner._velocity.x < 0:
			owner._velocity.x = min(0, owner._velocity.x + _delta * Consts.FRICTION)
			
	if owner.position.y > Consts.LOWER_BOUND_HEIGHT:
		owner.get_node("StateMachine").set_active(false)
	
func check_action():
	pass
