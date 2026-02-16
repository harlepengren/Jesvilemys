extends Node3D


@onready var test_stage_scene = preload('res://scenes/stages/test.tscn')
@onready var multiplayer_node = $Multiplayer

func _ready() -> void:
	var stage = test_stage_scene.instantiate()
	self.add_child(stage)
	
	var port = Globals.get_port()
	print("World loaded: starting on port ", port)
	
	if not multiplayer.is_server():
		multiplayer_node.start_client(port)
	

func _process(_delta: float) -> void:
	pass
