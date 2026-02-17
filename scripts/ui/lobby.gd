extends Control

var websocket := WebSocketPeer.new()
var connection_url := "ws://192.168.1.202:8080"
var is_connecting = false
var request_sent = false

func quick_start():
	# Send a websocket message to IP_ADDRESS requesting a new position
	request_game_port()

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
	
	match state:
		WebSocketPeer.STATE_OPEN:
			# Connection established, send port request
			if not request_sent:
				print("sending a websocket request")
				var request = JSON.stringify({"action": "request_port"})
				websocket.send_text(request)
				request_sent = true
			else:
				print("waiting")
			
			# Check for response
			while websocket.get_available_packet_count() > 0:
				var packet = websocket.get_packet()
				var response = packet.get_string_from_utf8()
				handle_port_response(response)
				
		WebSocketPeer.STATE_CLOSING:
			pass
			
		WebSocketPeer.STATE_CLOSED:
			var code = websocket.get_close_code()
			print("WebSocket closed with code: %d" % code)
			set_process(false)  # Stop processing
			is_connecting = false

func handle_port_response(response: String):
	var json = JSON.new()
	var parse_result = json.parse(response)
	
	if parse_result == OK:
		var data = json.data
		if data.has("port"):
			var assigned_port = data["port"]
			print("Received port: ", assigned_port)
			
			# Close the websocket
			websocket.close(1000, "Port received")
			
			# Use the port for your game
			start_game(assigned_port)
			

	else:
		push_error("Failed to parse response: " + response)

func start_game(port: int):
	# Your game server setup code here
	print("Starting game on server port: ", port)
	Globals.set_port(port)
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	
