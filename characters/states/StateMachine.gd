extends "res://scripts/state_machine.gd"

onready var idle = $Idle
onready var move = $Move
onready var jump = $Jump
onready var place = $Place
onready var throw = $Throw
onready var fall = $Fall
onready var die = $Die
onready var hurt = $Hurt

func reset():
	if current_state != null:
		if "is_current" in current_state:
			current_state.is_current = false 
	states_stack = []
	current_state = null
	_active = false
	initialize(start_state)

func _ready():
	states_map = {
		"idle": idle,
		"move": move,
		"jump": jump,
		"place": place,
		"throw" : throw,
		"fall" : fall,
		"die" : die,
		"hurt" : hurt
	}


func _change_state(state_name):
	# The base state_machine interface this node extends does most of the work.
	if not _active:
		return
	if state_name in ["place", "throw"]:
		states_stack.push_front(states_map[state_name])
	._change_state(state_name)


func _physics_process(_delta):
	if not _active:
		return
	if owner.action.action_type == 2:
		owner.action.clear_disposable()
		_change_state("throw")
	elif owner.action.action_type == 3:
		owner.action.clear_disposable()
		_change_state("place")
	current_state.check_action()


func _on_Character_state_updated():
	if not _active:
		return
	if current_state != null:
		current_state.update_animation()
