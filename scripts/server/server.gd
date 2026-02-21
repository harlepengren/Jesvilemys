extends Node

var ip_addr
var port

var peer: WebSocketMultiplayerPeer

func _ready():
	var user_args = OS.get_cmdline_user_args()
	
	ip_addr = null
	port = null
	
	# Parse arguments
	print(user_args)
	for arg in user_args:
		print(arg)
		if arg.begins_with("--ip_addr="):
			print(arg.substr(10))
			ip_addr = arg.substr(10)  # Length of "--ip_addr="
		elif arg.begins_with("--port="):
			print(arg.substr(7))
			var port_str = arg.substr(7)  # Length of "--port="
			port = int(port_str)
			Globals.set_port(port)
		elif arg.begins_with("--server"):
			Globals.is_server = true
	
	if Globals.is_server:
		# Validate and use the arguments
		if ip_addr != null and port != null:
			print("Connecting to IP: ", ip_addr, " on port: ", port)
			# Use your ip_addr and port here
		else:
			print("Error: Missing required arguments")
			if ip_addr == null:
				print("  Missing --ip_addr")
			if port == null:
				print("  Missing --port")
			
		start_server()
	
func start_server() -> void:
	print("starting the server . . .")
	peer = WebSocketMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	
func _process(_delta: float) -> void:
	if peer and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.poll()
