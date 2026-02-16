extends Node3D


@export var item_id: String

@onready var animation_reference = $'AnimationPlayer'
@onready var timer_reference = $'Timer'

var is_punched = false


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	animation_reference.play_backwards('shrink')
	animation_reference.queue('float')

	self.is_punched = false


func punch() -> bool:
	if animation_reference.current_animation == 'shrink':
		return false
	
	if self.is_punched:
		return false

	self.is_punched = true
	animation_reference.play('shrink')

	timer_reference.start(5)

	return true
