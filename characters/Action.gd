extends Node

# action 分为一次性的和连续的
# 除了 jump_action 以外都是一次性的，会被清空
# 对 agent 来说，每一次 set_action 会刷新掉动作信息
# agent 需要注意合法操作的处理
# 对 人类 来说，每一帧都获取输入，set_action，全部刷新
# 对 bot 来说，jump_action, throw_action, place_action 等一次性的动作，被检查了一次之后就要被清

# 只有三个取值, 0, +1, -1
var move := 0
var action_type := 0 # 0 : none, 1 : jump, 2 : throw, 3 : place
var action_args := Vector2.ZERO

func check_action():
	if move:
		if owner.state_machine.current_state in [owner.state_machine.hurt, owner.state_machine.die]:
			return "hurt 和 die 状态下不能移动！"
	if action_type == 0:
		return ""
	if action_type == 1:
		if owner.state_machine.current_state in [owner.state_machine.idle, owner.state_machine.move]:
			return ""
		else :
			return "jump 只能在 idle 和 move 状态下进行"
	if not (owner.state_machine.current_state in [owner.state_machine.idle, owner.state_machine.move, owner.state_machine.idle, owner.state_machine.jump, owner.state_machine.idle, owner.state_machine.fall]):
		return "throw / place 只能在 idle, move, jump, fall 状态下进行"
	if action_type == 2:
		# throw
		if action_args.length() <= Consts.MAX_V0:
			if owner.inventory.count_item("bomb") == 0:
				return "没有炸弹!"
			return ""
		else:
			return "throw 初速度超出限制"
	if action_type == 3:
		# throw
		if action_args.length() <= Consts.MAX_DISTANCE_PLACE:
			if owner.inventory.count_item("simple_block") == 0:
				return "没有方块!"
			return ""
		else:
			return "place 距离过远"
	return "未知错误"

func set_action(action):
	move = action["move"] - 1
	assert (move == 0 or move == 1 or move == -1)
	action_type = action["action_type"]
	action_args = Vector2(action["action_args"][0], action["action_args"][1])
	# 检查操作的合法性。如果是玩家，给出 warning。如果是 model，给出报错
	var result = check_action()
	if result != "":
		print(result)
		if owner._heuristic == "model":
			owner.agent.reward -= 0.2
		action_type = 0
		if owner.state_machine.current_state in [owner.state_machine.hurt, owner.state_machine.die]:
			move = 0
		
		

func reset():
	move = 0
	action_type = 0
	
func clear_disposable():
	action_type = 0

func _physics_process(delta):
	if not owner.active:
		reset()
		return
	if owner._heuristic != "model" :
		# 玩家可以控制
		var action = {}
		action["move"] = int (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) + 1
		if Input.is_action_just_pressed("jump"):
			action["action_type"] = 1
			action["action_args"] = [0, 0]
		elif Input.is_action_just_pressed("throw") and owner.main.cursor_indicator.mode == "throw":
			action["action_type"] = 2
			var v0 = Consts.K_V0 * (owner.main.cursor_indicator.cursor_metric_position - owner.main.cursor_indicator.character_metric_position)
			action["action_args"] = [v0.x, v0.y]
		elif Input.is_action_just_pressed("place") and owner.main.cursor_indicator.mode == "place":
			action["action_type"] = 3
			var d = (owner.main.cursor_indicator.cursor_metric_position - owner.main.cursor_indicator.character_metric_position)
			action["action_args"] = [d.x, d.y]
		else :
			action["action_type"] = 0
			action["action_args"] = [0, 0]
		set_action(action)
