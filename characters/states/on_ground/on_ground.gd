extends "../motion.gd"

# warning-ignore-all:unused_class_variable

func enter():
	owner._velocity = Vector2.ZERO
	if owner.active and (OS.get_ticks_msec() - owner.last_jump < Consts.JUMP_AGAIN_MARGIN):
		owner.last_jump = 0
		emit_signal("finished", "jump")

func check_action():
	if owner.action.action_type == 1:
		owner.action.clear_disposable()
		emit_signal("finished", "jump")

func update(_delta):
	.update(_delta)
	if owner._velocity.y > 0:
		emit_signal("finished", "fall")
