extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = "The winner is " + Global.winner
	$Camera2D.make_current()


func _on_exit_pressed():
	get_tree().quit()


func _on_restart_pressed():
	get_tree().change_scene("res://scenes/Theme.tscn")
