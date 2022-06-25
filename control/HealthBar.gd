extends Control

func _ready():
	$HealthOver.value = 100
	$HealthUnder.value = 100

func on_health_updated(new_health):
	var new_value = new_health * 1.0 / Consts.MAX_HP * 100
	$HealthOver.value = new_value
	$Tween.interpolate_property($HealthUnder, "value", $HealthUnder.value, new_value, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()
