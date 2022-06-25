extends CanvasLayer

func _ready():
	$DeathMessage.hide()

func player_died(s):
	$DeathMessage.show()
	$DeathMessage.text = s + " has been killed!"
	get_tree().paused = true
	if not Global.connected:
		yield(get_tree().create_timer(3.0), "timeout")
	get_tree().paused = false
	$DeathMessage.hide()
