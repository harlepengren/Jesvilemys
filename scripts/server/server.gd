extends Node

extends Node

	var ip_addr
	var port

func _ready():
	var args = OS.get_cmdline_args()
	var user_args = _get_user_args(args)
	
	ip_addr = null
	port = null
	
	# Parse arguments
	for arg in user_args:
		if arg.begins_with("--ip_addr="):
			ip_addr = arg.substr(10)  # Length of "--ip_addr="
		elif arg.begins_with("--port="):
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

func _get_user_args(args: Array) -> Array:
	var separator_idx = args.find("--")
	if separator_idx == -1:
		return []
	return args.slice(separator_idx + 1, args.size())
	
func start_server() -> void:
	print("starting the server . . .")
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
