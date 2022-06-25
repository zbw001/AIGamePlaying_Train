extends "../motion.gd"
onready var K = 0.5
var air_speed = Consts.WALK_SPEED

func update(_delta):
	var input_direction = get_input_direction()
	if owner.active and input_direction:
		owner._velocity.x = input_direction.x * air_speed * _delta
		owner.main.report(owner, "move_in_air", _delta)
	#owner._velocity *= (1-K * _delta)
	.update(_delta)
	if owner.is_on_floor():
		emit_signal("finished", "idle")

func check_action():
	pass
