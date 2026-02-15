extends Node

const IP_ADDRESS: String = "localhost"
const PORT:int = 42069

var peer: ENetMultiplayerPeer

func start_server() -> void:
	print("starting the server . . .")
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	
func start_client() -> void:
	print("starting the client . . .")
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
