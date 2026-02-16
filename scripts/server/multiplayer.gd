extends Node

const IP_ADDRESS: String = "192.168.1.202"
#const PORT:int = 8090

var peer: ENetMultiplayerPeer

#func start_server() -> void:
#	print("starting the server . . .")
#	peer = ENetMultiplayerPeer.new()
#	peer.create_server(PORT)
#	multiplayer.multiplayer_peer = peer
	
func start_client(port:int) -> void:
	print("starting the client . . .")
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(IP_ADDRESS, port)
	
	if error != OK:
		printerr("Failure connecting:",error)
	
	multiplayer.multiplayer_peer = peer
	
	
