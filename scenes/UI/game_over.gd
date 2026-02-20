extends Control

@onready var hits = $'MarginContainer/VBoxContainer/StatsPanel/MarginContainer/VBoxContainer/Hits'
@onready var damage_received = $'MarginContainer/VBoxContainer/StatsPanel/MarginContainer/VBoxContainer/DamageRecieved'
@onready var deaths = $'MarginContainer/VBoxContainer/StatsPanel/MarginContainer/VBoxContainer/Deaths'
@onready var winner = $'MarginContainer/VBoxContainer/WinnerPanel/WinnerLabel'

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("/root/GameManager").rpc_id(1,"get_stats")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_stats(winning_player, num_hits,num_damage, num_deaths):
	print("Received winner: " + winning_player)

	winner.text = winning_player + " Won!"
	hits.text = "Hits: %s"%[num_hits]
	damage_received.text = "Damage Received: %s"%[num_damage]
	deaths.text = "Deaths: %s"%[num_deaths]
