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
	unshrink.rpc()

func punched() -> bool:
	if animation_reference.current_animation == 'shrink':
		return false
	
	if self.is_punched:
		return false

	shrink.rpc()

	timer_reference.start(5)

	return true
	
@rpc("any_peer","call_local","reliable")
func shrink():
	self.is_punched = true
	animation_reference.play('shrink')
	
@rpc("any_peer","call_local","reliable")
func unshrink():
	animation_reference.play_backwards('shrink')
	animation_reference.queue('float')

	self.is_punched = false
