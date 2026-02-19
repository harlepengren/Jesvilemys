extends Node

# used to store 
var port
var is_server = false
var wordlist
var player_name

func _ready() -> void:
	wordlist = load_wordlist()
	player_name = generate_player_name()

func set_port(port_num:int):
	port = port_num
	
func get_port() -> int:
	return port
	
func load_wordlist() -> Array[String]:
	var words: Array[String] = []
	var file = FileAccess.open("res://data/eff_wordlist.txt", FileAccess.READ)
	
	if file == null:
		push_error("Could not open wordlist file")
		return words
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		# Split on tab and grab the second column (the word)
		var parts = line.split("\t")
		if parts.size() >= 2:
			words.append(parts[1])
	
	file.close()
	return words

func generate_player_name() -> String:
	if not wordlist:
		return "None"
		
	var word1:String = wordlist.pick_random().capitalize()
	var word2:String = wordlist.pick_random().capitalize()
	
	while word1 == word2:
		word2 = wordlist.pick_random().capitalize()
	
	return word1 + word2
