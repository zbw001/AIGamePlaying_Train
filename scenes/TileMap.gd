extends TileMap

var main = null

var items = []
var tiles_changed = []

func _ready():
	$CursorIndicator.tile_map = self

func reset():
	var l = len(tiles_changed)
	for i in range(l) :
		set_cellv(tiles_changed[-i-1][0], tiles_changed[-i-1][1])
	tiles_changed = []
	for item in items:
		item.cnt = 0
	$CursorIndicator.reset()
		
func mset_cellv(a, b) :
	tiles_changed.append([a, get_cellv(a)])
	set_cellv(a, b)

func upper_left_corner(vec):
	return Vector2(floor(vec.x / cell_size.x) * cell_size.x, floor(vec.y / cell_size.y) * cell_size.y)
	
func center_point_map(vec):
	return Vector2(vec.x * cell_size.x + cell_size.x / 2, vec.y * cell_size.y + cell_size.y / 2)

var Bomb = preload("res://entities/Bomb.tscn")

func add_bomb(p, v, c):
	var bomb = Bomb.instance()
	bomb.position = p
	bomb.velocity = v
	bomb.character = c
	bomb.main = main
	$Bombs.add_child(bomb)	
