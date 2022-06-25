extends Node

var EXPLODE_MAX_DAMAGE = 20
var MAX_KNOCK_SPEED = 2000
var EXPLODE_DAMAGE_DISTANCE = 250
var EXPLODE_BREAK_DISTANCE = 150
var MAX_DISTANCE_PLACE = 300
var MAX_DISTANCE_THROW = 300
var JUMP_AGAIN_MARGIN = 100 # ms
var NUM_PLAYER = 2
var NUM_CHARACTERS_PER_PLAYER = 2
var POINT_LIMIT = 5000 # ms
var MAX_HP = 100
var LOWER_BOUND_HEIGHT = 10000
var GRAVITY = 980 * 2
var FRICTION = 60 * 400
var K_V0 = 7
var WALK_SPEED = 200 * 60
var MIN_DURATION_HURT = 1000
var PLAYERS_COLOR = [Color(1.1, 0.9, 0.9), Color(0.9, 1, 1.2)]
var MAX_ITEM_CNT = 32
var MAX_ITEM_ENTITY_CNT = 6
var MAP_DIAMETER = 5000
var MAX_V0 = MAX_DISTANCE_THROW * K_V0

# 下面这些量在修改时，要对应修改节点属性
var BOMB_RADIUS = 10
var PLAYER_RECT_X = 5.784
var PLAYER_RECT_Y = 18.67

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
