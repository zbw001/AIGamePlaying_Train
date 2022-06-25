extends "res://scripts/state.gd"
# Collection of important methods to handle direction and animation.

var state_id = 6

onready var gravity = Consts.GRAVITY

var last_animation = null
var enter_time = null

func update_animation():
	var animation_name = "hurt"
	if owner.wounded:
		animation_name += "_wounded"
	owner.get_node("AnimatedSprite").play(animation_name)

func enter():
	last_animation = owner.get_node("AnimatedSprite").animation
	update_animation()
	if abs(owner._velocity.x) > 0.000001:
		owner.look_direction = -owner._velocity
	enter_time = OS.get_ticks_msec()

func update(_delta):
	owner._velocity.y += gravity * _delta
	owner._velocity = owner.move_and_slide(owner._velocity, Vector2.UP, false, 4, 0.785398, false)
	if owner.is_on_floor():
		if owner._velocity.x > 0:
			owner._velocity.x = max(0, owner._velocity.x - _delta * Consts.FRICTION)
		if owner._velocity.x < 0:
			owner._velocity.x = min(0, owner._velocity.x + _delta * Consts.FRICTION)
			
	if owner.position.y > Consts.LOWER_BOUND_HEIGHT:
		owner.hurt(owner.health, Vector2.ZERO)
	elif owner._velocity.length() < 0.000001 and owner.is_on_floor() and OS.get_ticks_msec() - enter_time > Consts.MIN_DURATION_HURT:
		owner._velocity = Vector2.ZERO
		emit_signal("finished", "idle")
	
	
func exit():
	owner.get_node("AnimatedSprite").play(last_animation)
	
func check_action():
	pass
