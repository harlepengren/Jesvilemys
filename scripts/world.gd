extends Node3D


@onready var test_stage_scene = preload('res://scenes/stages/test.tscn')


func _ready() -> void:
	var stage = test_stage_scene.instantiate()
	self.add_child(stage)

func _process(_delta: float) -> void:
	pass
