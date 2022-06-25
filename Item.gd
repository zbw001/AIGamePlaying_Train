extends Area2D

export var type = ""
var cnt = 0 setget set_cnt

func set_cnt(value) :
	cnt = min(Consts.MAX_ITEM_ENTITY_CNT, value)
	$CollisionShape2D/Label.text = str(cnt)
	if cnt == 0:
		hide()
	else :
		show()

func _ready():
	owner.items.append(self)
	hide()

func _on_Item_body_entered(body):
	if not ("dead" in body):
		return
	body.get_node("Inventory").add_item(type, cnt)
	set_cnt(0)
