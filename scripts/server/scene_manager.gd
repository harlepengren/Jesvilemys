extends Node

var level_info:Dictionary
var level_ids:Array =[]

var current_level:String 	# Name of current level that we can look up in level_info

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Scene Manager Ready")
			
	var file = FileAccess.open("res://scenes/levels.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
		
	level_info = json.data
	
	for key in level_info:
		level_ids.append(key)
						
	if Globals.is_server:
		select_new_level()
		multiplayer.peer_connected.connect(_on_peer_connected)
		
func _on_peer_connected(_id:int):	
	print("SceneManager: sending current level to " + str(_id))
	rpc_id(_id,"set_current_level",current_level)
	load_level.rpc_id(_id)

func get_current_level():
	print("Getting current level:", current_level)
	return level_info[current_level]
	
@rpc("authority","call_local","reliable")
func set_current_level(level_id):
	print("Setting current level")
	current_level = level_id
				
@rpc("authority","call_local","reliable")
func load_level() -> void:
	get_node("/root/World").load_scene()

func choose_random_level():
	return level_ids.pick_random()
	
@rpc("authority","call_local","reliable")
func select_new_level():
	if Globals.is_server:
		current_level = SceneManager.choose_random_level()
		print("Selected:",current_level)
		
		# send to everyone
		rpc("set_current_level",current_level)
		load_level.rpc()
