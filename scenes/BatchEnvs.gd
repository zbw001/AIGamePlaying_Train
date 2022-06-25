extends Node2D

export var num_envs_per_worker = 16 # 如果要改，必须一起改 config。(应该会有检查

var main_scene = preload("res://scenes/Main.tscn")

	
func _ready():
	for i in range(num_envs_per_worker):
		var container = ViewportContainer.new()
		var viewport = Viewport.new()
		
		var s = main_scene.instance()
		s.env_name = str(i)
		
		viewport.add_child(s)
		container.add_child(viewport)
		#container.stretch = true
		$Scenes.add_child(container)
		
		viewport.size = get_viewport().get_visible_rect().size / 4
		#container.rect_size = get_viewport().get_visible_rect().size / 4
		viewport.set_size_override_stretch(true)
		viewport.set_size_override(true, get_viewport().get_visible_rect().size)

func _process(_delta):
	Global.connected = $Sync.connected

			
		
