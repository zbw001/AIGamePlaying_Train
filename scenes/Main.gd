extends Node2D

# Main 代表是是一场游戏的开始

func _ready():
	$MainMap.main = self
	$HUD/InventoryUI.main = self
	$HUD/Bar/Label.main = self
	$ReceiveSignal.main = self
	$MainMap/CursorIndicator.main = self
	init_game()
	
onready var hud = $HUD
onready var map = $MainMap
onready var cursor_indicator = $MainMap/CursorIndicator

var env_name = null
var done = false

var winner = ""
var message = "Start !"
var player_name = ["Red", "Blue"]
var cur_character = null

var characters = []
var characters_list = []
var num_alive = []
var Character = preload("res://characters/character.tscn")

var point_left = 0
var cur_player_id = 0
var cur_character_id = 0
var is_over = false setget set_is_over
var turn_num = 0

func to_metric_len(l, fr):
	return Utils.convert_len(l, fr, cursor_indicator)

func to_metric(vec, fr):
	return cursor_indicator.to_local(fr.to_global(vec))
	
func to_metric_global(vec):
	return cursor_indicator.to_local(vec)

func get_env_info():
	var ret = {
		"MAX_V0" : Consts.MAX_V0,
		"MAX_DISTANCE_PLACE" : Consts.MAX_DISTANCE_PLACE,
		"BOMB_RADIUS" : Consts.BOMB_RADIUS,
		"PLAYER_RECT_WIDTH" : Consts.PLAYER_RECT_X,
		"PLAYER_RECT_HEIGHT" : Consts.PLAYER_RECT_Y,
		"GRAVITY" : Consts.GRAVITY,
		"WALK_SPEED" : Consts.WALK_SPEED,
		"BLOCK_SIZE" : map.cell_size.x,
		"FRICTION" : Consts.FRICTION, # 在地面上时的，滑动摩擦力的加速度
	}
	return ret

func reset():
	done = false
	map.reset()
	init_game()
	

func init_game():
	winner = ""
	message = "Start !"
	turn_num = 0
	cur_character = null
	point_left = 0
	cur_player_id = 0
	cur_character_id = 0
	if characters.empty():
		# 创建角色
		var _i = 0
		for i in range(Consts.NUM_PLAYER):
			characters.append([])
			num_alive.append(Consts.NUM_CHARACTERS_PER_PLAYER)
			for j in range(Consts.NUM_CHARACTERS_PER_PLAYER):
				var c = Character.instance()
				c.player_id = i
				c.character_id = j
				characters[i].append(c)
				c.get_node("Inventory").add_item("simple_block", 20)
				c.get_node("Inventory").add_item("bomb", 4)
				c.position.x = - 200 * 2 + j * 80
				c.position.y = 300
				c.main = self
				c.global_character_id = _i
				characters_list.append(c)
				_i += 1
				c.init_agent("P" + str(c.player_id) + "C" + str(c.character_id))
				map.get_node("Characters").add_child(c)
				if i == 1:
					c.position.x *= -1
				c.tile_map = map
	else :
		for i in range(Consts.NUM_PLAYER):
			num_alive[i] = (Consts.NUM_CHARACTERS_PER_PLAYER)
			for j in range(Consts.NUM_CHARACTERS_PER_PLAYER):
				var c = characters[i][j]
				c.reset()
				c.get_node("Inventory").add_item("simple_block", 20)
				c.get_node("Inventory").add_item("bomb", 4)
				c.position.x = - 900 * 2 + j * 80
				c.position.y = 300
				if i == 1:
					c.position.x *= -1
	set_is_over(false)
	new_turn()
	change_focus(characters[0][0])

func new_turn() :
	if turn_num % (Consts.NUM_CHARACTERS_PER_PLAYER * Consts.NUM_PLAYER * 2) == 0:
		for item in map.items:
			item.cnt = item.cnt + 3
	turn_num += 1
	if turn_num >= 20:
		done = true
	change_focus(characters[cur_player_id][cur_character_id])
	#characters[cur_player_id][cur_character_id].get_node("Inventory").clear()
	characters[cur_player_id][cur_character_id].get_node("Inventory").add_item("simple_block", 5)
	if characters[cur_player_id][cur_character_id].inventory.count_item("bomb") == 0:
		characters[cur_player_id][cur_character_id].inventory.add_item("bomb", 1)
	#characters[cur_player_id][cur_character_id].get_node("Inventory").add_item_by_id("bomb", 2)
	point_left = Consts.POINT_LIMIT
	message = "%s Player: Character %d; %d points left" % [player_name[cur_player_id], cur_character_id, point_left]
	
func change_focus(new_character):
	if cur_character != null :
		cur_character.set_active(false)
	new_character.set_active(true)
	cur_character = new_character
	$HUD/InventoryUI.refresh()
	
func report(character, type, delta) :
	# print(character, type, delta)
	if character == cur_character:
		if type == "move":
			point_left = max(0, point_left - delta * 1000)
		if type == "jump":
			point_left = max(0, point_left - 100)
		if type == "move_in_air":
			point_left = max(0, point_left - 1.5 * delta * 1000)
		if type == "throw":
			point_left = max(0, point_left - 1000)
		if type == "place":
			point_left = max(0, point_left - 100)
			
		if type == "die":
			point_left = min(point_left, 0)
			message = "%s Player: Character %d is dead"  % [player_name[cur_player_id], cur_character_id + 1]
		else:
			message = "%s Player: Character %d; %d points left" % [player_name[cur_player_id], cur_character_id + 1, point_left]
	if type == "die":
		hud.player_died("%s Player: Character %d"  % [player_name[character.player_id], character.character_id + 1])
		num_alive[character.player_id] -= 1
		if num_alive[character.player_id] == 0:
			var players_left = []
			for i in range(Consts.NUM_PLAYER):
				if num_alive[i] > 0:
					players_left.append(i)
			if len(players_left) == 1:
				point_left = -1
				_game_ended(players_left[0])
		
	if point_left == 0:
		point_left = -1
		_turn_ended()
	
func _next_character():
	cur_player_id += 1
	if cur_player_id >= Consts.NUM_PLAYER:
		cur_player_id = 0
		cur_character_id += 1
	if cur_character_id >= Consts.NUM_CHARACTERS_PER_PLAYER:
		cur_character_id = 0
		
	
		
func _turn_ended():
	var timer = Timer.new()
	timer.set_wait_time(2)
	timer.set_one_shot(true)
	add_child(timer)
	timer.start()
	cur_character.set_active(false)
	if not Global.connected:
		yield(timer, "timeout")
	timer.queue_free()
	
	_next_character()
	while characters[cur_player_id][cur_character_id].dead:
		_next_character()
	new_turn()
	
func set_is_over(value):
	for i in range(Consts.NUM_PLAYER):
		for j in range(Consts.NUM_CHARACTERS_PER_PLAYER):
			if not characters[i][j].dead:
				characters[i][j].state_machine._on_Character_state_updated()
	
func _game_ended(winner) :
	set_is_over(true)
	for i in range(Consts.NUM_PLAYER):
		for j in range(Consts.NUM_CHARACTERS_PER_PLAYER):
			characters[i][j].set_active(false)
	send_reward(winner, 100)
	send_reward(1 - winner, -100)
	message = "%s Player is the winner." % player_name[winner]
	if not Global.connected:
		yield(get_tree().create_timer(5.0), "timeout")
	winner = player_name[winner]
	Global.winner = winner
	done = true
	
func send_reward(player_id, reward) :
	for i in range(Consts.NUM_CHARACTERS_PER_PLAYER):
		characters[player_id][i].agent.reward += reward
