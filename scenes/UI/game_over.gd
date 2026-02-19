extends Control

@onready var hits = $hits
@onready var damage_received = $damage_received
@onready var deaths = $deaths
@onready var winner = $winner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("/root/GameManager").rpc_id(1,"get_stats")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update_stats(winning_player,num_hits,num_damage,num_deaths):
	print("received winner: " + winning_player)
	winner.text = winning_player + " Won!"
	hits.text = "Hits: %s"%[num_hits]
	damage_received.text = "Damage Received: %s"%[num_damage]
	deaths.text = "Deaths: %s"%[num_deaths]
	
