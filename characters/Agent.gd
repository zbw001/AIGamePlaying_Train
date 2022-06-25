extends Node

var env_name = null
var env = null
var agent_name = null
var reward = 0
var done = false
var last_inventory = [0, 0]
var k_reward = [1.0 / Consts.MAX_ITEM_CNT * 1, 1.0 / Consts.MAX_ITEM_CNT * 50]

var center := Vector2.ZERO

func zero_reward():
	reward = 0

func reset():
	# 清除 action
	zero_reward()
	owner.action.reset()
	last_inventory = [0, 0]
	
func get_obs():
	if not owner.active:
		return null
# The observation of the agent, think of what is the key information that is needed to perform the task, try to have things in coordinates that a relative to the play

# return a dictionary with the "obs" as a key, you can have several keys
	var obs = {}
	var metric_center = owner.main.to_metric(owner.tile_map.upper_left_corner(owner.tile_map.to_local(owner.global_position)), owner.tile_map)
	obs["character_id"] = owner.global_character_id
	obs["points"] = [owner.main.point_left]
	obs["state"] = owner.state_machine.current_state.state_id
	var n_character = Consts.NUM_CHARACTERS_PER_PLAYER * Consts.NUM_PLAYER
	var c_r_p = []
	var i_r_p = []
	var i_n = []
	var c_i = []
	var c_h = []
	var c_m = []
	for i in range(n_character) :
		var c_id = (owner.global_character_id + i) % n_character
		var c = owner.main.characters_list[c_id]
		var metric_pos = owner.main.to_metric_global(c.global_position) # 不能用 to_metric，见 to_global 的定义
		c_r_p.append(metric_pos.x - metric_center.x)
		c_r_p.append(metric_pos.y - metric_center.y)
		c_i.append(c.inventory.count_item("simple_block"))
		c_i.append(c.inventory.count_item("bomb"))
		c_h.append(c.health)
		var metric_velocity = owner.main.to_metric(c._velocity, c.get_node("..")) - owner.main.to_metric(Vector2.ZERO, c.get_node(".."))
		c_m.append(int(metric_velocity.length() > 1e-5))
	for item in owner.tile_map.items:
		var metric_pos = owner.main.to_metric_global(item.global_position)
		i_r_p.append(metric_pos.x - metric_center.x)
		i_r_p.append(metric_pos.y - metric_center.y)
		i_n.append(item.cnt)
	obs["characters_relative_position"] = c_r_p
	obs["characters_moving"] = c_m
	obs["items_relative_position"] = i_r_p
	obs["items_num"] = i_n
	obs["characters_inventory"] = c_i
	obs["characters_health"] = c_h
	obs["turn_num"] = int((owner.main.turn_num - 1) / (Consts.NUM_PLAYER * Consts.NUM_CHARACTERS_PER_PLAYER)) % 2
	
	var map = [[], [], []]
	
	var center_map = owner.tile_map.world_to_map(owner.tile_map.to_local(owner.global_position))
	# 这样写不会包括 20！-20~19 正好 20 项
	for i in range(-20, 20) :
		map[0].append([])
		map[1].append([])
		map[2].append([])
		for j in range(-20, 20) :
			map[0][-1].append(0)
			map[1][-1].append(0)
			map[2][-1].append(0)
			var v = owner.tile_map.get_cellv(Vector2(i + center_map.x, j + center_map.y))
			if v == -1:
				map[0][-1][-1] = 1
			elif v == 11:
				map[1][-1][-1] = 1
			else:
				map[2][-1][-1] = 1
	obs["map"] = map	
	
	#print(obs)
	return obs

func clear_actions():
	pass # set_action 即可

func get_reward():
	var ret = reward
	zero_reward()
	return ret + shaping_reward()

func shaping_reward():
	var inventory = [owner.inventory.count_item("simple_block"), owner.inventory.count_item("bomb")]
	var r = (inventory[0] - last_inventory[0]) * k_reward[0] + (inventory[1] - last_inventory[1]) * k_reward[1]
	last_inventory = inventory
	return r

func set_heuristic(heuristic):
	# sets the heuristic from "human" or "model" nothing to change here
	owner._heuristic = heuristic
   
func get_obs_space():
	# typs of obs space: box, discrete, repeated (for variable length observations)
	return {
		# 地图信息 (打包) 为字符串
		# 剩余的 Point
		"character_id": {
			"size": 4,
			"space": "discrete"
		},
		"points": {
			"size": [1],
			"space": "box",
			"low": 0,
			"high": Consts.POINT_LIMIT
		},
		"state": {
			"size": 8,
			"space": "discrete"
		},
		"characters_relative_position": {
			"size": [8],
			"space" : "box",
			"low": -Consts.MAP_DIAMETER,
			"high": Consts.MAP_DIAMETER,
		},
		"items_relative_position": {
			"size": [len(owner.tile_map.items)*2],
			"space" : "box",
			"low": -Consts.MAP_DIAMETER,
			"high": Consts.MAP_DIAMETER
		},
		"items_num": {
			"size": [len(owner.tile_map.items)],
			"space": "box",
			"low": 0,
			"high": Consts.MAX_ITEM_ENTITY_CNT
		},
		"characters_moving": {
			"size": [4],
			"space": "box",
			"low": 0,
			"high": 1
		},
		"characters_inventory": {
			"size" : [8],
			"space": "box",
			"low": 0,
			"high": Consts.MAX_ITEM_CNT
		},
		"characters_health": {
			"size" : [4],
			"space": "box",
			"low": 0,
			"high": Consts.MAX_HP
		},
		"map": { # 看看怎么编码？空方块是否需要放一层？
			"size": [3, 40, 40],
			"space" : "box",
			"low": 0,
			"high": 1
		},
		"turn_num": {
			"size": 2,
			"space" : "discrete"
		}
	   }

func get_action_space():
	# Define the action space of you agent, below is an example, GDRL allows for discrete and continuous state spaces (assuming the RL algorithm allows it)
	return {
		"move" : {
			 "size": 3,
			"action_type": "discrete"
		   },        
		"action_type" : {
			 "size": 4,
			"action_type": "discrete"
		   },
		"action_args": {
			"size": 2,
			"action_type": "continuous",
			"low": 0,
			"high": 1,
		   }
	   }


func set_action(action):
	if action["action_type"] == 2:
		var x = action["action_args"][0] * Consts.MAX_V0 * cos(2 * PI * action["action_args"][1])
		var y = action["action_args"][0] * Consts.MAX_V0 * sin(2 * PI * action["action_args"][1])
		action["action_args"] = [x, y]
	if action["action_type"] == 3:
		var x = action["action_args"][0] * Consts.MAX_DISTANCE_PLACE * cos(2 * PI * action["action_args"][1])
		var y = action["action_args"][0] * Consts.MAX_DISTANCE_PLACE * sin(2 * PI * action["action_args"][1])
		action["action_args"] = [x, y]
	owner.action.set_action(action)
