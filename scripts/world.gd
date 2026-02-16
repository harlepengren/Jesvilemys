extends Node3D


@export var possible_item_souls: Array[String]
@export var current_item_souls: Dictionary[String, String]

@onready var test_stage_scene = preload('res://scenes/stages/test.tscn')

@onready var title_board_reference = $'CanvasLayer/TitleBoard'
@onready var item_timer_reference = $'ItemTimer'


func _ready() -> void:
	var stage = test_stage_scene.instantiate()
	self.add_child(stage)

	item_timer_reference.start(5)

func _process(delta: float) -> void:
	pass

func _on_item_timer_timeout() -> void:
	title_board_reference.change_colors(Color(0.8, 0.741, 0.98), Color(0.29, 0.0, 0.749))
	title_board_reference.display_text('Item souls switched places!')

	item_timer_reference.start(5)
