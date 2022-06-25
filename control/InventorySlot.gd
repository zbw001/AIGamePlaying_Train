extends Control

var item_id
var container

func set_item_id(_item_id):
	item_id = _item_id
	var texture = load(GDInv_ItemDB.REGISTRY[item_id].attributes["texture"])
	$TextureRect/TextureButton.texture_normal = texture
	$TextureRect/TextureButton.texture_hover = texture
	
func set_label(text):
	$TextureRect/Label.text = text

func _on_TextureButton_pressed():
	container.emit_signal("_on_pressed", item_id)

func set_frame_texture(texture) :
	$TextureRect.texture = texture
