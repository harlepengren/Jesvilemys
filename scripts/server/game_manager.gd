extends Node

enum State {WAITING, RUNNING, END}
var current_game_state:State
var timer:Timer
var time_since_last_update:float

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
		if time_since_last_update > 1:
			get_node("/root/World").rpc("update_timer_display",timer.time_left)
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
		get_tree().paused = true
		_start_timer(10,true)
		get_node("/root/World").rpc("show_game_over")
	elif current_game_state == State.END:
		current_game_state = State.WAITING
		get_node("/root/World").rpc("hide_game_over")
		get_tree().paused = false
		
@rpc("any_peer", "reliable")
func register_hit(attacker_id:int,victim_id:int):
	if not Globals.is_server:
		return
		
	print("Hit: (Attacker: %s), (Victim:%s)"%[attacker_id,victim_id])
	if not hit_stats.has(attacker_id):
		hit_stats[attacker_id] = {"hits_given": 1, "hits_received": 0}
	else:
		hit_stats[attacker_id]["hits_given"] += 1
		
	if not hit_stats.has(victim_id):
		hit_stats[victim_id] = {"hits_given": 0, "hits_received": 1}
	else:
		hit_stats[victim_id]["hits_received"] += 1
		
	# Calculate knockback direction and tell the victim
	var attacker = get_node("/root/World/%d" % attacker_id)
	var victim = get_node("/root/World/%d" % victim_id)
	var direction = sign((victim.position - attacker.position).x)
	victim.rpc_id(victim_id,"punched", Vector3(direction * 8.0, 1.0, 0.0))
	
	
