extends Control

@onready var hits = $hits
@onready var damage_received = $damage_received
@onready var deaths = $deaths

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("/root/GameManager").rpc_id(1,"get_stats")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
@rpc("any_peer","call_remote","reliable")
func update_stats(num_hits,num_damage,num_deaths):
	hits.text = "Hits: %s"%[num_hits]
	damage_received.text = "Damage Received: %s"%[num_damage]
	deaths.text = "Deaths: %s"%[num_deaths]
	
