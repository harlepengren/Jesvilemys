extends Node3D


@export var item_id: String

@onready var animation_reference = $'AnimationPlayer'

var is_punched = false


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass


func punch() -> bool:
	if animation_reference.current_animation == 'shrink':
		return false
	
	if self.is_punched:
		return false

	self.is_punched = true
	animation_reference.play('shrink')

	return true
