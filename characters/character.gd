extends KinematicBody2D

signal direction_changed(new_direction)
signal state_updated

# 本来的 active : 指玩家可以操作
# 如何区分玩家不能操作，但是 Bot 可以操作的例子？
#	根据 _heuristic 的设置，需要一个自定义的 Input 处理工具!
# 玩家需要初始化函数来重设所有东西。

export var _heuristic := "player"
var main = null
var health = Consts.MAX_HP
var dead = false
var player_id = -1 setget set_player
var character_id = -1
var global_character_id = -1
onready var action = $Action
onready var inventory = $Inventory
onready var state_machine = $StateMachine
onready var agent = $Agent

var look_direction = Vector2.RIGHT setget set_look_direction

var last_jump = 0

func reset():
	health = Consts.MAX_HP
	$HealthBar.on_health_updated(health)
	dead = false
	look_direction = Vector2.RIGHT
	_velocity = Vector2.ZERO
	set_active(false)
	set_wounded(false)
	action.reset()
	inventory.reset()
	$Agent.reset()
	state_machine.reset()

func init_agent(agent_name):
	$Agent.env_name = main.env_name
	$Agent.env = main
	$Agent.agent_name = agent_name

func _process(_delta):
	# 为优化游戏体验设置，不考虑 agent 的输入
	if active and Input.is_action_just_pressed("jump"):
		last_jump = OS.get_ticks_msec()

func set_look_direction(value):
	look_direction = value
	if value.x > 0:
		$AnimatedSprite.scale.x = 1
	if value.x < 0:
		$AnimatedSprite.scale.x = -1
	emit_signal("direction_changed", value)

var _velocity = Vector2.ZERO

# tile_map 和 cursor_indicator 的实例, 在 MainMap 的 _ready() 中设置
# 通过这两个实例访问 tile_map 和 cursor_indicator 的信息，避免直接根据路径获取实例 (为了保证各个模块的独立性)
# cursor_indicator 的成员 map_position : Vector2 表示鼠标当前位置在 TileMap 上对应方格的坐标 (应当是整数

var active = false setget set_active
var wounded = false setget set_wounded
var tile_map = null

func set_player(value):
	player_id = value
	$AnimatedSprite.modulate = Consts.PLAYERS_COLOR[player_id]

func set_focus(flag):
	if flag:
		$Camera2D.make_current()

func _ready():
	set_focus(false)
	$Agent.set_heuristic(_heuristic)

func set_active(value):
	if active == value:
		return
	active = value
	set_focus(value)
	emit_signal("state_updated")
	
func set_wounded(value):
	wounded = value
	emit_signal("state_updated")

func set_dead(value):
	dead = value
	set_active(not value)
	set_process_input(not value)
	set_physics_process(not value)
	#$StateMachine.set_active(not value)
	#set_collision_layer_bit(0, false)
	#$CollisionPolygon2D.set_deferred("disabled", value)
	main.report(self, "die", 0)
	
func hurt(delta, vec) :
	if dead:
		return
	health = max(0, health - delta)
	_velocity = vec
	if health <= Consts.MAX_HP / 2:
		set_wounded(true)
	if health == 0:
		$StateMachine._change_state("die")
	else :
		$StateMachine._change_state("hurt")
	$HealthBar.on_health_updated(health)
