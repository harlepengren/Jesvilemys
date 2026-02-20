extends Node3D


@onready var player_name_reference = $'CanvasLayer/VBoxContainer/PlayerNamePanel/Label'


var websocket := WebSocketPeer.new()
var connection_url
var is_connecting = false
var request_sent = false


func _ready():
	player_name_reference.text = "Player Name: " + Globals.player_name

	var connection_details = load_config()

	if connection_details.has("server_ip") and connection_details.has("signal_server_port"):
		var server_ip = connection_details["server_ip"]
		var server_port = connection_details["signal_server_port"]

		connection_url = "ws://"+server_ip+":"+str(server_port)
	print("Server info: " + connection_url)

func quick_start():
	# Send a websocket message to IP_ADDRESS requesting a new position
	request_game_port()
	
func play_alone():
	Globals.set_port(-1)
	start_game()

func load_config() -> Dictionary:
	var file = FileAccess.open("res://scripts/server/config.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	print(json.data)
	return json.data

func request_game_port():
	var err = websocket.connect_to_url(connection_url)
	if err != OK:
		push_error("Failed to connect to WebSocket: " + str(err))
		return
	
	print("Connecting to server port ...")
	is_connecting = true
	request_sent = false
	

func _process(_delta):
	if not is_connecting:
		return
		
	websocket.poll()
	
	var state = websocket.get_ready_state()
	print("State: ", state, " Request sent: ", request_sent)
	
	match state:
		WebSocketPeer.STATE_OPEN:
			# Connection established, send port request
			if not request_sent:
				print("sending a websocket request")
				var request = JSON.stringify({"action": "request_port"})
				var err = websocket.send_text(request)
				
				if err == OK:
					print("Request successfully sent")
					request_sent = true
				else:
					print("Error sending request")

			else:
				print("waiting")
			
			# Check for response
			while websocket.get_available_packet_count() > 0:
				var packet = websocket.get_packet()
				var response = packet.get_string_from_utf8()
				handle_port_response(response)
				
		WebSocketPeer.STATE_CLOSING:
			print("closing")
			
		WebSocketPeer.STATE_CLOSED:
			print("Packets remaining: ", websocket.get_available_packet_count())
			
			var code = websocket.get_close_code()
			var reason = websocket.get_close_reason()
			print("WebSocket closed with code: %d, reason: %s" % [code, reason])
			set_process(false)  # Stop processing
			is_connecting = false

func handle_port_response(response: String):
	var json = JSON.new()
	var parse_result = json.parse(response)
	
	if parse_result == OK:
		var data = json.data
		print(data)
		if data.has("port"):
			var assigned_port = int(data["port"])
			print("Received port: ", assigned_port)
			
			Globals.set_port(assigned_port)
		else:
			print("Invalid port")
			
		if data.has("ip_addr"):
			Globals.set_ip(data["ip_addr"])
		else:
			print("Invalid IP address")
		
		# Close the websocket
		websocket.close(1000, "Port received")
			
		# Use the port for your game
		start_game()
			

	else:
		push_error("Failed to parse response: " + response)

func start_game():
	var port = Globals.get_port()
	# Your game server setup code here
	print("Starting game on server port: ", port)
	GameManager.rpc_id(1, "register_name", Globals.player_name)
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	
