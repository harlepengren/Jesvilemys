extends Node3D

@export var possible_item_souls: Array[String]
@export var current_item_souls: Dictionary[String, String]

@onready var player_scene = preload('res://scenes/player.tscn')

@onready var title_board_reference = $'CanvasLayer/MarginContainer/TitleBoard'
@onready var time_remaining_reference = $'CanvasLayer/MarginContainer/TimeRemainingLabel'

@onready var item_timer_reference = $'ItemTimer'

@onready var camera_reference = $'Camera3D'

# Load and instantiate the scene
@onready var game_over_scene = preload("res://scenes/UI/game_over.tscn")
var game_over_instance
@onready var multiplayer_node = $Multiplayer

var playing_alone = false

var current_level_info

func _enter_tree() -> void:
	if Globals.port == -1:
		playing_alone = true

	if playing_alone:
		# Delete multiplayer nodes
		$Multiplayer.queue_free()
		$MultiplayerSpawner.queue_free()
	
func _ready() -> void:	
	var port = Globals.get_port()
	print("World loaded: starting on port ", port)

	if not Globals.is_server and not playing_alone:
		print("World: starting client")
		multiplayer_node.start_client(port)
	elif Globals.is_server:
		print("Server: not starting client")
	elif playing_alone:
		print("Playing alone")

		# Load Player
		var player = player_scene.instantiate()

		player.model_reference = player.get_node('CharlieModel')
		player.animation_reference = player.model_reference.get_node('AnimationPlayer')

		player.model_reference.show()

		add_child(player)

		if Globals.port == -1:
			# Load Level
			SceneManager.current_level = SceneManager.choose_random_level()
			load_scene()

	item_timer_reference.start(10)

	#self.spawn_simple_player() # Remove for multiplayer

func load_scene():
	current_level_info = SceneManager.get_current_level()
	if current_level_info == null:
		push_error("world load scene is null")
		return
	
	var stage = load(current_level_info["level_stage"]).instantiate()
	self.add_child(stage)
	var background = load(current_level_info["level_background"]).instantiate()
	self.add_child(background)

func _on_item_timer_timeout() -> void:
	title_board_reference.change_colors(Color(0.8, 0.741, 0.98), Color(0.29, 0.0, 0.74))
	title_board_reference.display_text('Item souls swapped places!')

	for item_type in self.current_item_souls.keys():
		current_item_souls[item_type] = self.possible_item_souls.pick_random()

	item_timer_reference.start(10)

func _on_death_boundary_body_entered(body: Node3D) -> void:
	body.position = Vector3(0.0, 10.0, 0.0)
	
	if body.get_multiplayer_authority() == multiplayer.get_unique_id():
		print("Player Died:",body.get_multiplayer_authority())
		get_node("/root/GameManager").player_died.rpc()


func spawn_simple_player(): # Used for basic testing
	var player = player_scene.instantiate()
	self.add_child(player)


func _on_begin_game_button_pressed() -> void:
	$'CanvasLayer/MarginContainer/BeginGameButton'.release_focus()
	get_node('/root/GameManager').rpc_id(1, 'begin_game')


# Updates time remaining on main game screen
@rpc("authority", "call_remote", "unreliable")
func update_timer_display(time):
	time_remaining_reference.text = "Time Remaining: " + "%02d" % [time]

@rpc("authority", "call_remote", "reliable")
func show_game_over():
	game_over_instance = game_over_scene.instantiate()
	$CanvasLayer.add_child(game_over_instance)
	print("Showing game over")
	
@rpc("authority", "call_remote", "reliable")
func hide_game_over():
	print("hiding game over")
	game_over_instance.queue_free()
	
# Updates the time on the game over screen
@rpc("authority","call_remote","unreliable")
func update_time(time):
	var time_remaining = $CanvasLayer/GameOver/MarginContainer/VBoxContainer/NewGameLabel
	
	time_remaining.text = "Time to Next Game: %02d seconds"%[time]
