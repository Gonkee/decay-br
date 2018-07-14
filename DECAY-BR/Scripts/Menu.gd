extends Node

func _ready():
	pass

func _on_Join_pressed():
	var ip = get_node("Server IP input").get_text()
	var port = int(get_node("Port input").get_text())
	var max_peers = int(get_node("Max peers input").get_text())
	var peer_name = get_node("Name input").get_text()
	Global.start_game(false, ip, port, max_peers, peer_name)
	pass

func _on_Start_Server_pressed():
	var ip = get_node("Server IP input").get_text()
	var port = int(get_node("Port input").get_text())
	var max_peers = int(get_node("Max peers input").get_text())
	var peer_name = get_node("Name input").get_text()
	Global.start_game(true, ip, port, max_peers, peer_name)
	pass