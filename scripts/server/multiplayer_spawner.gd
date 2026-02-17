extends MultiplayerSpawner

@export var network_player: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(remove_player)

func spawn_player(id:int) -> void:
	print("peer_connected fired for id: ", id)
	if not multiplayer.is_server(): 
		print("Not the server, skipping spawn.")
		return
	
	print("Spawn player for id:", id)
	var player: Node = network_player.instantiate()
	player.name = str(id)
	
	get_node(spawn_path).add_child(player)
	
	print("Tree:",get_tree().root.get_children())  # See what's under root
	
func remove_player(id: int) -> void:
	if not multiplayer.is_server():
		return

	var player = get_node(spawn_path).get_node_or_null(str(id))
	if player:
		player.queue_free()
		print("Removed player: ", id)
