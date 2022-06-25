extends Node2D

var tile_map = null
var mode = ""
var cursor_map_position = null
var cursor_metric_position = null
var character_metric_position = null
var main = null

onready var line = $Line2D
var max_points = 250


onready var pictex = load("res://assets/alpha.png")

func reset():
	mode = ""
	cursor_map_position = null
	cursor_metric_position = null
	character_metric_position = null

func _draw():
	line.clear_points()
	if cursor_metric_position == null:
		return
	if mode == "place":
		draw_texture_rect(pictex, Rect2(cursor_metric_position, tile_map.cell_size), false)
	if mode == "throw":
		line.clear_points()
		var pos = character_metric_position
		var vel = (cursor_metric_position - character_metric_position) * Consts.K_V0
		var delta = 1.0 / 60 # 一帧为单位
		for i in max_points:
			line.add_point(pos)
			vel.y += Consts.GRAVITY * delta
			pos += vel * delta
			if pos.y > Consts.LOWER_BOUND_HEIGHT:
				break

func _process(delta):
	if main.cur_character._heuristic != "model":
		# 均在 tilemap 的坐标系下计算
		var global_v = get_global_mouse_position()
		var metric_v = main.to_metric_global(global_v)
		character_metric_position = main.to_metric_global(main.cur_character.global_position)
		var d = metric_v.distance_to(character_metric_position)
		var inventory = main.cur_character.get_node("Inventory")
		
		if inventory.item_selected != null and inventory.count_item(inventory.item_selected) > 0:
			if GDInv_ItemDB.get_item_by_id(inventory.item_selected).attributes["placeable"]:
				mode = "place"
				cursor_map_position = tile_map.world_to_map(tile_map.to_local(global_v))
				if d <= Consts.MAX_DISTANCE_PLACE and tile_map.get_cellv(cursor_map_position) == -1:
					cursor_metric_position = main.to_metric(tile_map.upper_left_corner(tile_map.to_local(global_v)), tile_map)
				else :
					cursor_map_position = null
					cursor_metric_position = null
					mode = ""
			elif GDInv_ItemDB.get_item_by_id(inventory.item_selected).attributes["throwable"]:
				mode = "throw"
				if d <= Consts.MAX_DISTANCE_THROW:
					cursor_metric_position = metric_v
				else :
					cursor_metric_position = null
					mode = ""
			else:
				mode = ""
		else:
			mode = ""
	else :
		mode = ""
	update()
