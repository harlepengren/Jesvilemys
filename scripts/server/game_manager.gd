extends Node

enum State {WAITING, RUNNING, END}
var current_game_state:State
var timer:Timer
var time_since_last_update:float
var winner:String = ""

@onready var hit_stats:Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.is_server:
		current_game_state = State.WAITING


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Globals.is_server:
		# Only the server gets to do things
		return
		
	if current_game_state == State.WAITING and (multiplayer.get_peers().size()) >= 2:
		current_game_state = State.RUNNING
		_start_timer(60.0)		
		
	if current_game_state == State.RUNNING:
		get_tree().paused = false
		time_since_last_update += delta
		if time_since_last_update > 0.6:
			get_node("/root/World").rpc("update_timer_display",timer.time_left)
			time_since_last_update = 0.0
	elif current_game_state == State.END:
		time_since_last_update += delta
		if time_since_last_update > 0.8:
			get_node("/root/World").rpc("update_time",timer.time_left)
			time_since_last_update = 0.0

func _start_timer(time,always=false):
	# Create the timer
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = time
	timer.one_shot = true
	
	if always:
		timer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	time_since_last_update = 10 # Force initial broadcast
	print("timer started")
	
func _on_timer_timeout():
	print("Timer finished")
	timer.queue_free()
	
	if current_game_state == State.RUNNING:
		current_game_state = State.END
		calculate_score()
		#get_tree().paused = true
		_start_timer(25,true)
		get_node("/root/World").rpc("show_game_over")
	elif current_game_state == State.END:
		current_game_state = State.WAITING
		get_node("/root/World").rpc("hide_game_over")
		get_tree().paused = false
		
func calculate_score():
	if not Globals.is_server:
		return
		
	# +/- 1 point for hits; -5 for death
	var winning_player:String
	var winning_score = -10000
	
	for player in hit_stats:
		var score = 100 + hit_stats[player]["hits_given"] - hit_stats[player]['hits_received'] - 5*hit_stats[player]['deaths']
		if score > winning_score:
			winning_player = hit_stats[player]["player_name"]
			winning_score = score
			
	winner = winning_player
	print("Winner: " + winner)
	return
		
@rpc("any_peer","call_local","reliable")
func register_name(player_name:String):
	if not Globals.is_server:
		return
		
	var player_id = multiplayer.get_remote_sender_id()
	
	if not hit_stats.has(player_id):
		print("registering " + player_name)
		hit_stats[player_id] = {"player_name":player_name, "hits_given": 0, "hits_received": 0, "deaths": 0}
	else:
		hit_stats[player_id]["name"] = player_name

@rpc("any_peer", "reliable")
func register_hit(attacker_id:int,victim_id:int):
	if not Globals.is_server:
		return
		
	if not hit_stats.has(attacker_id):
		hit_stats[attacker_id] = {"hits_given": 1, "hits_received": 0, "deaths": 0}
	else:
		hit_stats[attacker_id]["hits_given"] += 1
		
	if not hit_stats.has(victim_id):
		hit_stats[victim_id] = {"hits_given": 0, "hits_received": 1, "deaths":0}
	else:
		hit_stats[victim_id]["hits_received"] += 1
		
	# Calculate knockback direction and tell the victim
	var attacker = get_node("/root/World/%d" % attacker_id)
	var victim = get_node("/root/World/%d" % victim_id)
	var direction = sign((victim.position - attacker.position).x)
	victim.rpc_id(victim_id,"punched", Vector3(direction * 8.0, 1.0, 0.0))

@rpc("any_peer", "reliable")
func player_died(player_id:int):
	if not hit_stats.has(player_id):
		hit_stats[player_id] = {"hits_given": 0, "hits_received": 0, "deaths": 1}
	hit_stats[player_id]["deaths"] += 1

@rpc("any_peer","call_local","reliable")
func get_stats():
	if not Globals.is_server: return
	
	var id = multiplayer.get_remote_sender_id()
	
	if not hit_stats.has(id):
		hit_stats[id] = {"player_name":"", "hits_given": 0, "hits_received": 0, "deaths": 0}
	
	print("sending stats to " + str(id))
	rpc_id(id, "receive_stats", winner, hit_stats[id]["hits_given"],hit_stats[id]["hits_received"],hit_stats[id]["deaths"])

@rpc("authority", "reliable")
func receive_stats(game_winner:String, hits_given: int, hits_received: int, deaths: int):
	if Globals.is_server: return
	
	get_node("/root/World/CanvasLayer/GameOver").update_stats(game_winner,hits_given, hits_received, deaths)
