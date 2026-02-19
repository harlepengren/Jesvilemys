extends Node

var level_info
var level_ids:Array =[]

var current_level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("scene manager")
	if not Globals.is_server:
		return
		
	var file = FileAccess.open("res://scenes/levels.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
		
	level_info = json.data["levels"]
	
	for item in level_info:
		if item.has("level_id"):
			level_ids.append(item["level_id"])
			
	# Choose a random level
	rpc("set_current_level",SceneManager.choose_random_level())
	$World.load_scene.rpc()
			
func get_current_level():
	return current_level
	
@rpc("authority","call_remote","reliable")
func set_current_level(level_id):
	print("Scene Selected: ", level_id)
	if level_ids.has(level_id):
		for item in level_info:
			if item["level_id"] == level_id:
				current_level = item
				break
				
func choose_random_level():
	return level_ids.pick_random()
