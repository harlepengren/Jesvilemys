extends Node3D

@onready var multiplayer_node = $Multiplayer
@export var possible_item_souls: Array[String]
@export var current_item_souls: Dictionary[String, String]

@onready var test_stage_scene = preload('res://scenes/stages/noodle_plains.tscn')
@onready var test_background_scene = preload('res://scenes/backgrounds/noodle_plains.tscn')

@onready var snowy_tops_stage_scene = preload('res://scenes/stages/snowy_tops.tscn')
@onready var snowy_tops_background_scene = preload('res://scenes/backgrounds/snowy_tops.tscn')

@onready var player_scene = preload('res://scenes/player.tscn')

@onready var title_board_reference = $'CanvasLayer/TitleBoard'
@onready var item_timer_reference = $'ItemTimer'

@onready var camera_reference = $'Camera3D'

# Load and instantiate the scene
@onready var game_over_scene = preload("res://scenes/UI/game_over.tscn")
var game_over_instance

var playing_alone = false

func _enter_tree() -> void:
	if Globals.port == -1:
		playing_alone = true

	if playing_alone:
		# Delete multiplayer nodes
		$Multiplayer.queue_free()
		$MultiplayerSpawner.queue_free()
	
func _ready() -> void:
	var stage = test_stage_scene.instantiate()
	self.add_child(stage)
	
	var port = Globals.get_port()
	print("World loaded: starting on port ", port)
	
	if not Globals.is_server and not playing_alone:
		print("World: starting client")
		multiplayer_node.start_client(port)
	elif Globals.is_server:
		print("Server: not starting client")
	elif playing_alone:
		print("Playing alone")
		var player_scene = preload("res://scenes/player.tscn")
		var player = player_scene.instantiate()
		add_child(player)		

	var background = test_background_scene.instantiate()
	self.add_child(background)

	item_timer_reference.start(10)

	#self.spawn_simple_player() # Remove for multiplayer

func _on_item_timer_timeout() -> void:
	title_board_reference.change_colors(Color(0.8, 0.741, 0.98), Color(0.29, 0.0, 0.74))
	title_board_reference.display_text('Item souls swapped places!')

	for item_type in self.current_item_souls.keys():
		current_item_souls[item_type] = self.possible_item_souls.pick_random()

	item_timer_reference.start(10)


func spawn_simple_player(): # Used for basic testing
	var player = player_scene.instantiate()
	self.add_child(player)
	
@rpc("authority", "call_remote", "unreliable")
func update_timer_display(time):
	$CanvasLayer/TimeRemaining.text = "Time Remaining: " + "%02d" % [time]
	
@rpc("authority", "call_remote", "reliable")
func show_game_over():
	game_over_instance = game_over_scene.instantiate()
	$CanvasLayer.add_child(game_over_instance)
	print("Showing game over")
	$CanvasLayer.print_tree_pretty()
	
@rpc("authority", "call_remote", "reliable")
func hide_game_over():
	print("hiding game over")
	game_over_instance.queue_free()
	
