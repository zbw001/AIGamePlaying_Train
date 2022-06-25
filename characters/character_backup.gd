extends KinematicBody2D



export var speed = Vector2(200.0, 350.0)
export(NodePath) var inventory
onready var gravity = 980
var _velocity = Vector2.ZERO

# tile_map 和 cursor_indicator 的实例, 在 MainMap 的 _ready() 中设置
# 通过这两个实例访问 tile_map 和 cursor_indicator 的信息，避免直接根据路径获取实例 (为了保证各个模块的独立性)
# cursor_indicator 的成员 map_position : Vector2 表示鼠标当前位置在 TileMap 上对应方格的坐标 (应当是整数

var active = false
var tile_map = null
var last_jump = 0

func set_focus(flag):
	$Camera2D.make_current()

func _ready():
	set_focus(false)
	
func get_direction():
	var direction_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if not active:
		direction_x = 0
	var direction_y = 0
	if (active and is_on_floor() and Input.is_action_just_pressed("jump")):
		direction_y = -1
	else:
		if active and Input.is_action_just_pressed("jump"):
			last_jump = OS.get_ticks_msec()
		if is_on_floor():
			if (OS.get_ticks_msec() - last_jump < Consts.JUMP_AGAIN_MARGIN):
				last_jump = 0
				direction_y = -1
				
	return Vector2(direction_x, direction_y)
	
func calculate_move_velocity(linear_velocity, direction, speed):
	var velocity = linear_velocity
	velocity.x = speed.x * direction.x
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
	return velocity
	
func get_new_animation():
	var animation_new = ""
	if is_on_floor():
		if abs(_velocity.x) > 0.1:
			animation_new = "walk"
		else:
			animation_new = "stand"
	else:
		if _velocity.y > 0:
			animation_new = "fall"
		else:
			animation_new = "jump"
	#if is_shooting:
	#	animation_new += "_weapon"
	return animation_new
	
func _physics_process(delta):
	_velocity.y += gravity * delta
	
	var direction = get_direction()
	# 为啥不用 delta，因为相对固定吗 ? 
	_velocity = calculate_move_velocity(_velocity, direction, speed)
	_velocity = move_and_slide(_velocity, Vector2.UP)

	if direction.x != 0:
		if direction.x > 0:
			$AnimatedSprite.scale.x = 1
		else:
			$AnimatedSprite.scale.x = -1

	#var is_shooting = false
	#if Input.is_action_just_pressed("use"):
	#	is_shooting = gun.shoot(sprite.scale.x)

	var animation = get_new_animation()
	if animation != $AnimatedSprite.animation:
		$AnimatedSprite.play(animation)
	
	if active:
		if $Inventory.item_selected != null and GDInv_ItemDB.get_item_by_id($Inventory.item_selected).attributes["placeable"]:
			if $Inventory.count_item($Inventory.item_selected) > 0:
				if Game.cursor_indicator.map_position != null:
					var block_id = GDInv_ItemDB.get_item_by_id($Inventory.item_selected).attributes["blockID"]
					# 等有在跳起时中放置方块的素材后再设置
					if Input.is_action_pressed("place"):
						if tile_map.get_cellv(Game.cursor_indicator.map_position) == -1:
							tile_map.m(Game.cursor_indicator.map_position, block_id)
							$Inventory.remove_item_by_id($Inventory.item_selected, 1)
					#if Input.is_action_just_pressed("break"):
						#animation = "break"
						#$AnimatedSprite.play(animation)
					#	tile_map.set_cell(cursor_indicator.map_position, -1)

func activate():
	active = true
	set_focus(true)
	
func deactivate():
	active = false
	set_focus(false)
