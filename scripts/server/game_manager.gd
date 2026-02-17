extends Node

enum State {WAITING, RUNNING, END}
var current_game_state:State
var timer:Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_game_state = State.WAITING


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Globals.is_server:
		# Only the server gets to do things
		return
		
	if current_game_state == State.WAITING and (multiplayer.get_peers().size() +1) >= 2:
		current_game_state = State.RUNNING
	
		# Create the timer
		timer = Timer.new()
		add_child(timer)
		timer.wait_time = 60.0
		timer.one_shot = true
		timer.timeout.connect(_on_timer_timeout)
		timer.start()
		print("timer started")
		
func _on_timer_timeout():
	current_game_state = State.END
	print("Timer finished")
	timer.queue_free()
