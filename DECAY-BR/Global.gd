extends Node

var current_scene

onready var Game
onready var Player
onready var FPV
onready var Inventory
onready var HUD
onready var SpawnPoint

func _ready():
	current_scene = get_tree().get_root().get_child( get_tree().get_root().get_child_count() - 1 )
	pass

func set_scene(scene):
	current_scene.queue_free()
	current_scene = load(scene).instance()
	get_tree().get_root().add_child(current_scene)
	
func start_game(is_server, ip, port, max_peers, peer_name):
	current_scene.queue_free()
	current_scene = load("res://Scenes/Game.tscn").instance()
	get_tree().get_root().add_child(current_scene)
	current_scene.network_init(ip, port, max_peers, peer_name)
	if(is_server):
		current_scene.start_server()
	else:
		current_scene.join_server()
	pass
	set_global_nodes()

func set_global_nodes():
	Game = get_node("/root/Game")
	SpawnPoint = get_node("/root/Game/World/SpawnPoint")
	Player = Game.my_player
	FPV = Player.get_node("Head/FPV")
	Inventory = Player.get_node("Head/Inventory")
	HUD = Player.get_node("Head/FPV/HUD")