extends Node

var peer: ENetMultiplayerPeer

#func start_server() -> void:
#	print("starting the server . . .")
#	peer = ENetMultiplayerPeer.new()
#	peer.create_server(PORT)
#	multiplayer.multiplayer_peer = peer
	
func start_client(port:int) -> void:
	print("starting the client . . .")
	peer = ENetMultiplayerPeer.new()
	print("attempting to connect on: " + Globals.get_ip_addr() + ":"+ str(port))
	var error = peer.create_client(Globals.get_ip_addr(), port)
	
	if error != OK:
		printerr("Failure connecting:",error)
	
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected_to_server():
	print("Successfully connected to server!")

func _on_connection_failed():
	printerr("Connection to server failed!")
	
	
