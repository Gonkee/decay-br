extends Node

var peer
var my_name
var my_id

var tick_duration = 1 / 20
var tick_time = 0

var ip
var port
var max_peers

var players = {}
var updatables = []
var transform

var my_player

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	set_process(true)
	pass
	
func network_init(ip, port, max_peers, my_name):
	self.ip = ip
	self.port = port
	self.max_peers = max_peers
	self.my_name = my_name

func _process(delta):
	if(Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()
	if(peer != null):
		if(peer.get_connection_status() == 2):
			tick_time += delta
			if(tick_time >= tick_duration):
				tick_time = 0
				tick()

func tick():
	if(weakref(my_player).get_ref()):
		rpc_unreliable("player_transform", my_id, my_player.get_info_set())
	if(my_id == 1):
		var info_sets = []
		for i in updatables:
			if(!weakref(i).get_ref()):
				info_sets.append(null)
			else:
				info_sets.append(i.get_info_set())
		rpc_unreliable("update_updatables", info_sets)

remote func delete_player(id):
	if(id == my_id):
		my_player.queue_free()
		get_node("WorldView").set_current(true)
		rpc("delete_player", id)
	else:
		players[id].queue_free()

func start_server():
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_server(port, max_peers)
	if(error != OK):
		join_server()
		return
	get_tree().set_network_peer(peer)
	my_id = get_tree().get_network_unique_id()
	init_player()
	
func join_server():
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	my_id = get_tree().get_network_unique_id()
	init_player()

func init_player():
	my_player = load("res://Scenes/Player/PlayerController.tscn").instance()
	add_child(my_player)
	players[my_id] = my_player
	my_player.set_name(str(my_id))
	my_player.init(my_id)
	my_player.set_translation(get_node("World/SpawnPoint").get_translation())
	my_player.FPV.set_current(true)
	my_player.HUD.set_visible(true)

func _connected_ok():
	rpc_id(1, "register_player", my_id)
	
func _player_connected(id):
	print(str("player connected ", id))
func _player_disconnected(id):
	print(str("player disconnected ", id))
func _connected_fail():
	print("connected fail")
func _server_disconnected():
	print("server disconnected")

remote func add_updatable(scene_path, info):
	if my_id != 1:
		rpc_id(1, "add_updatable", scene_path, info)
		return
	var new = load(scene_path).instance()
	add_child(new)
	new.set_id(updatables.size())
	new.set_info_set(info)
	updatables.append(new)

remote func delete_updatable(id, repeat):
	updatables[id].queue_free()
	if repeat:
		rpc("delete_updatable", id, false)

remote func update_updatables(info_sets):
	for i in info_sets:
		if(updatables.size() < info_sets.size()):
			updatables.resize(info_sets.size())
		if i != null:
			if(updatables[i.id] == null):
				var new = load(i.updatable_scene_path).instance()
				add_child(new)
				new.set_id(i.id)
				new.set_info_set(i)
				updatables[i.id] = new
			elif weakref(updatables[i.id]).get_ref():
				updatables[i.id].set_info_set(i)

remote func player_transform(peer_id, info):
	players[peer_id].set_info_set(info)

remote func register_player(peer_id):
	# If I'm the server, let the new guy know about existing players
	if(get_tree().is_network_server()):
		# Send the info of existing players to new player
		for e in players.values():
			rpc_id(peer_id, "register_player", e.get_id())
			if(e.get_id() != my_id):
				rpc_id(e.get_id(), "register_player", peer_id)
	
	# Store the info
	players[peer_id] = generate_player(peer_id)

sync func reset_players():
	my_player.reset()

func reset_all():
	rpc("reset_players")

func generate_player(peer_id):
	var new_player = load("res://Scenes/Player/PlayerBasic.tscn").instance()
	add_child(new_player)
	new_player.set_name(str(peer_id))
	new_player.init(peer_id)
	new_player.set_translation(Global.SpawnPoint.get_translation())
	return new_player
	