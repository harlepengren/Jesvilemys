extends Node3D


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


func _ready() -> void:
	var stage = test_stage_scene.instantiate()
	self.add_child(stage)

	var background = test_background_scene.instantiate()
	self.add_child(background)

	item_timer_reference.start(10)

	self.spawn_simple_player() # Remove for multiplayer

func _on_item_timer_timeout() -> void:
	title_board_reference.change_colors(Color(0.8, 0.741, 0.98), Color(0.29, 0.0, 0.74))
	title_board_reference.display_text('Item souls swapped places!')

	for item_type in self.current_item_souls.keys():
		current_item_souls[item_type] = self.possible_item_souls.pick_random()

	item_timer_reference.start(10)


func spawn_simple_player(): # Used for basic testing
	var player = player_scene.instantiate()
	self.add_child(player)
