extends Area2D
onready var G = Consts.GRAVITY
onready var NUM_PLAYER = Consts.NUM_PLAYER
onready var NUM_CHARACTERS_PER_PLAYER = Consts.NUM_CHARACTERS_PER_PLAYER
onready var tween = $Tween

var velocity = Vector2.ZERO
var collide = 0
var character = null
var main = null

signal bomb_exploded(bomb)

#检查是否爆炸

func get_damage(position1, position2):
	var distance = position1.distance_to(position2)
	if distance <= Consts.EXPLODE_DAMAGE_DISTANCE:
		return 1.0 * Consts.EXPLODE_MAX_DAMAGE * (Consts.EXPLODE_DAMAGE_DISTANCE - distance) / Consts.EXPLODE_DAMAGE_DISTANCE
	else:
		return 0
	
func get_velocity(position1, position2):
	var distance = position1.distance_to(position2)
	if distance <= Consts.EXPLODE_DAMAGE_DISTANCE:
		var speed = 1.0 * Consts.MAX_KNOCK_SPEED * (Consts.EXPLODE_DAMAGE_DISTANCE - distance) / Consts.EXPLODE_DAMAGE_DISTANCE
		return speed * (position1 - position2).normalized()
	else:
		return Vector2(0,0)

func _on_Bomb_body_entered(body):
	if "dead" in body:
		if body.dead:
			return
	if body == character:
		return
	if collide:
		return
	collide = 1
	
	for i in range (NUM_CHARACTERS_PER_PLAYER):
		for j in range (NUM_PLAYER):
			var target = main.characters[i][j]
			var Delta_velocity = get_velocity(target.position, position)
			var Damage = get_damage(target.position, position)
			#print(Delta_velocity)
			if Damage > 0:
				var ad = Damage
				if ad >= target.health:
					ad = target.health + 100
				if character.player_id == target.player_id:
					main.send_reward(target.player_id, - ad)
				else :
					main.send_reward(character.player_id, ad)
					main.send_reward(target.player_id, - ad)
				target.hurt(Damage, Delta_velocity)
	
	var BLOCK_NUM = int(Consts.EXPLODE_BREAK_DISTANCE / main.map.cell_size.x + 2)
	var center = main.map.world_to_map(main.map.to_local(global_position))
	#print(BLOCK_NUM)
	for i in range (-BLOCK_NUM, BLOCK_NUM):
		for j in range (-BLOCK_NUM, BLOCK_NUM):
			var target_position = main.map.center_point_map(center + Vector2(i, j))
			var distance = target_position.distance_to(position)
			if distance <= Consts.EXPLODE_BREAK_DISTANCE and main.map.get_cellv(main.map.world_to_map(target_position)) != 11:
				main.map.mset_cellv(main.map.world_to_map(target_position), -1)
	
	tween.interpolate_property($AnimatedSprite, "scale", Vector2.ZERO, $AnimatedSprite.scale, 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$AnimatedSprite.play("explode")
	tween.connect("tween_all_completed", self, "queue_free")
	tween.start()

func _ready():
	# 调试语句，可以加一个在场景里看看有没有按照预期飞行
	# initialize(Vector2(1, 1))\
	
	$AnimatedSprite.animation = "create"

func _physics_process(delta):
	if collide == 0 :
		velocity.y += G * delta
		position += velocity * delta
		if velocity.y > Consts.LOWER_BOUND_HEIGHT:
			queue_free()
