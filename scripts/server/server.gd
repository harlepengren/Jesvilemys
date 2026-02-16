extends Node

var ip_addr
var port

var peer: ENetMultiplayerPeer

func _ready():
	var args = OS.get_cmdline_args()
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
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
