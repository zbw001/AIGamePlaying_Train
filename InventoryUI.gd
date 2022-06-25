extends HBoxContainer

var childs: Dictionary = {};

signal _on_pressed

export(Texture) var texture_selected
export(Texture) var texture_not_selected

var main = null

# Called when the node enters the scene tree for the first time.
func _ready():
	for item_id in GDInv_ItemDB.REGISTRY.keys():
		var scene = preload("res://control/InventorySlot.tscn")
		var ins = scene.instance()
		ins.container = self
		ins.set_item_id(item_id)
		add_child(ins)
		childs[item_id] = ins
	pass
	
func _process(delta):
	if main.cur_character == null:
		return
	for item_id in GDInv_ItemDB.REGISTRY.keys():
		childs[item_id].set_label(str(main.cur_character.get_node("Inventory").count_item(item_id)))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func refresh() :
	for item_id in GDInv_ItemDB.REGISTRY.keys():
		childs[item_id].set_frame_texture(texture_not_selected)
	if main.cur_character.get_node("Inventory").item_selected != null:
		childs[main.cur_character.get_node("Inventory").item_selected].set_frame_texture(texture_selected)

func _on_InventoryUI__on_pressed(item_id):
	if main.cur_character.get_node("Inventory").item_selected == item_id:
		return
	childs[item_id].set_frame_texture(texture_selected)
	if main.cur_character.get_node("Inventory").item_selected != null:
		childs[main.cur_character.get_node("Inventory").item_selected].set_frame_texture(texture_not_selected)
	main.cur_character.get_node("Inventory").item_selected = item_id
