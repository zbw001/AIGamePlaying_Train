extends Node
# --fixed-fps 2000 --disable-render-loop
# export 似乎没什么意义，因为会被覆盖
var action_repeat := 8
var n_action_steps = 0

const MAJOR_VERSION := "0"
const MINOR_VERSION := "1" 
const DEFAULT_PORT := 11008
const DEFAULT_SEED := 1
const DEFAULT_ACTION_REPEAT := 8
var client : StreamPeerTCP = null
var connected = false
var message_center
var should_connect = true
var agents_list
var agents_dict
var need_to_send_obs = false
var args = null
onready var start_time = OS.get_ticks_msec()
var initialized = false
var just_reset = false
var env_names
var agent_names
var envs_dict
var envs_list

func _ready():
	yield(get_tree().root, "ready")
	get_tree().set_pause(true) 
	_initialize()
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().set_pause(false) 
		
func _get_nodes():
	agents_list = get_tree().get_nodes_in_group("AGENT")
	envs_list = get_tree().get_nodes_in_group("ENVIRONMENT")
	envs_dict = {}
	env_names = []
	for env in envs_list:
		env_names.append(env.env_name)
		envs_dict[env.env_name] = env
	agents_dict = {}
	for agent in agents_list:
		assert(agent.env_name != null)
		assert(agent.agent_name != null)
		if not (agent.env_name in agents_dict.keys()) :
			agents_dict[agent.env_name] = {}
		assert (not (agent.agent_name in agents_dict[agent.env_name].keys()))
		agents_dict[agent.env_name][agent.agent_name] = agent
	agent_names = agents_dict[env_names[0]].keys()

func _set_heuristic(heuristic):
	for agent in agents_list:
		agent.set_heuristic(heuristic)

func _handshake():
	print("performing handshake")
	
	var json_dict = _get_dict_json_message()
	assert(json_dict["type"] == "handshake")
	var major_version = json_dict["major_version"]
	var minor_version = json_dict["minor_version"]
	if major_version != MAJOR_VERSION:
		print("WARNING: major verison mismatch ", major_version, " ", MAJOR_VERSION)  
	if minor_version != MINOR_VERSION:
		print("WARNING: major verison mismatch ", minor_version, " ", MINOR_VERSION)
		
	print("handshake complete")

func _get_dict_json_message():
	# returns a dictionary from of the most recent message
	# this is not waiting
	while client.get_available_bytes() == 0:
		if client.get_status() == 3:
			print("server disconnected status 3, closing")
			get_tree().quit()
			return null

		if !client.is_connected_to_host():
			print("server disconnected, closing")
			get_tree().quit()
			return null
		OS.delay_usec(10)
		
	var message = client.get_string()
	var json_data = JSON.parse(message).result
	
	return json_data

func _send_dict_as_json_message(dict):
	client.put_string(to_json(dict))

func _get_obs_space(dict) :
	var ret = {}
	for k in dict:
		ret[k] = dict[k].get_obs_space()
	return ret

func _get_action_space(dict) :
	var ret = {}
	for k in dict:
		ret[k] = dict[k].get_action_space()
	return ret

func _send_env_info():
	var json_dict = _get_dict_json_message()
	assert(json_dict["type"] == "env_info")
	var message = {
		"type" : "env_info",
		#"obs_size": agents[0].get_obs_size(),
		"observation_space": _get_obs_space(agents_dict[env_names[0]]),
		"action_space": _get_action_space(agents_dict[env_names[0]]),
		"agent_names": agent_names,
		"env_names": env_names,
		"env_info" : envs_list[0].get_env_info()
	   }
	_send_dict_as_json_message(message)


func connect_to_server():
	print("Waiting for one second to allow server to start")
	OS.delay_msec(1000)
	print("trying to connect to server")
	client = StreamPeerTCP.new()
	
	#set_process(true)"localhost" was not working on windows VM, had to use the IP
	var ip = "127.0.0.1"
	var port = _get_port()
	var connect = client.connect_to_host(ip, port)
	OS.delay_msec(1000)
	
	print(connect, client.get_status())
	client.set_no_delay(true) # TODO check if this improves performance or not
	
	return client.get_status() == 2

func _get_args():
	print("getting command line arguments")
	var arguments = {}
	for argument in OS.get_cmdline_args():
		# Parse valid command-line arguments into a dictionary
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
			
	return arguments   

func _get_port():    
	return int(args.get("port", DEFAULT_PORT))

func _set_seed():
	var _seed = int(args.get("env_seed", DEFAULT_SEED))
	seed(_seed)

func _set_action_repeat():
	action_repeat = int(args.get("action_repeat", DEFAULT_ACTION_REPEAT))
	

func disconnect_from_server():
	client.disconnect_from_host()

func _initialize():
	_get_nodes()
	
	args = _get_args()
	connected = connect_to_server()
	if connected:
		_set_heuristic("model")
		_handshake()
		_send_env_info()
	else:
		_set_heuristic("human")  
		
	_set_seed()
	_set_action_repeat()
	initialized = true  

func _physics_process(delta): 
	# two modes, human control, agent control
	# pause tree, send obs, get actions, set actions, unpause tree
	if n_action_steps % action_repeat != 0:
		n_action_steps += 1
		return
		 
	n_action_steps += 1
	
	if connected:
		get_tree().set_pause(true) 
		
		if just_reset:
			just_reset = false
			var obs = _get_obs_from_agents()
		
			var reply = {
				"type": "reset",
				"obs": obs
			}
			_send_dict_as_json_message(reply)
			# this should go straight to getting the action and setting it on the agent, no need to perform one phyics tick
			get_tree().set_pause(false) 
			return
		
		if need_to_send_obs:
			need_to_send_obs = false
			var reward = _get_reward_from_agents()
			var dones = _get_dones() # agent + environment
			# 确保已经重置了 done 的 environment，从而这个 obs 是新的
			var obs = _get_obs_from_agents()
			
			var reply = {
				"type": "step",
				"obs": obs,
				"reward": reward,
				"dones": dones
			}
			_send_dict_as_json_message(reply)
		
		var handled = handle_message()
	else:
		_reset_all_environments_if_done()

func handle_message() -> bool:
	# get json message: reset, step, close
	var message = _get_dict_json_message()
	
	if message["type"] == "close":
		print("received close message, closing game")
		get_tree().quit()
		get_tree().set_pause(false) 
		return true
		
	if message["type"] == "reset":
		print("resetting all environments")
		_reset_all_environments()
		just_reset = true
		get_tree().set_pause(false) 
		#print("resetting forcing draw")
#        VisualServer.force_draw()
#        var obs = _get_obs_from_agents()
#        print("obs ", obs)
#        var reply = {
#            "type": "reset",
#            "obs": obs
#        }
#        _send_dict_as_json_message(reply)   
		return true
		
	if message["type"] == "call":
		var method = message["method"]
		var returns = _call_method_on_agents(method)
		var reply = {
			"type": "call",
			"returns": returns
		}
		print("calling method from Python")
		_send_dict_as_json_message(reply)   
		return handle_message()
	
	if message["type"] == "action":
		var action = message["action"]
		_set_agent_actions(action) 
		need_to_send_obs = true
		get_tree().set_pause(false) 
		return true
		
	print("message was not handled")
	return false

func _call_method_on_agents(method):
	var returns = []
	for agent in agents_list:
		returns.append(agent.call(method))
		
	return returns

func _reset_all_environments():
	for env in envs_list:
		env.reset()
		
func _reset_all_environments_if_done():
	for env in envs_list:
		if env.done:
			env.reset() 

func _get_obs_from_agents():
	var obs = {}
	for env in env_names:
		obs[env] = {}
		for agent in agent_names:
			var _obs = agents_dict[env][agent].get_obs()
			if _obs:
				obs[env][agent] = _obs
	return obs
	
func _get_reward_from_agents():
	var rewards = {}
	for env in env_names:
		rewards[env] = {}
		for agent in agent_names:
			rewards[env][agent] = agents_dict[env][agent].get_reward()
			agents_dict[env][agent].zero_reward()
	return rewards    
	
func _get_dones():
	var dones = {}
	for env in env_names:
		dones[env] = {}
		# 干脆不传递 agent 的 dones
		#for agent in agent_names:
		#	if agents_dict[env][agent].done:
		#		dones[env][agent] = true
	for env in env_names:
		if envs_dict[env].done:
			envs_dict[env].reset()
			dones[env]["__all__"] = true
		else :
			dones[env]["__all__"] = false
	return dones
	
func _set_agent_actions(actions):
	for agent in agents_list:
		agent.clear_actions() # 清除当前动作数据
	for env in actions.keys():
		for agent in actions[env].keys():
			agents_dict[env][agent].set_action(actions[env][agent])
	
