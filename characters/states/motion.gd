extends "res://scripts/state.gd"
# Collection of important methods to handle direction and animation.

onready var gravity = Consts.GRAVITY

func get_input_direction():
	var input_direction = Vector2(
			owner.action.move,
			0
	)
	return input_direction

func update_look_direction(direction):
	if not owner.active :
		return
	if direction and owner.look_direction != direction:
		owner.look_direction = direction

func update(_delta):
	owner._velocity.y += gravity * _delta
	owner._velocity = owner.move_and_slide(owner._velocity, Vector2.UP, false, 4, 0.785398, false)
