extends Node

var peer: WebSocketMultiplayerPeer

#func start_server() -> void:
#	print("starting the server . . .")
#	peer = ENetMultiplayerPeer.new()
#	peer.create_server(PORT)
#	multiplayer.multiplayer_peer = peer
	
func start_client(port:int) -> void:
	print("starting the client . . .")
	peer = WebSocketMultiplayerPeer.new()
	var url = "ws://3.143.102.5:" + str(port)
	print("attempting to connect on: " + url)
	var error = peer.create_client(url)
	
	if error != OK:
		printerr("Failure connecting:",error)
	
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected_to_server():
	print("Successfully connected to server!")

func _on_connection_failed():
	printerr("Connection to server failed!")
	
func _process(_delta: float) -> void:
	if peer and multiplayer.multiplayer_peer == peer:
		peer.poll()
	
	
