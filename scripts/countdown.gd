extends Control


signal countdown_finish

@onready var label_reference = $'Label'
@onready var timer_reference = $'Timer'

var running_timer = false
var running_timer_aftertext = false

var aftertext = ''


func update_timer() -> void:
	label_reference.text = str(int(ceil(timer_reference.time_left)))

func _process(delta: float) -> void:
	if running_timer: update_timer()


func _on_timer_timeout() -> void:
	if running_timer:
		running_timer = false

		running_timer_aftertext = true
		label_reference.text = aftertext

		timer_reference.start(1.0)

	elif running_timer_aftertext:
		running_timer_aftertext = false
		hide()
 
		countdown_finish.emit()


func start_countdown(time_sec: float, aftertext_string: String):
	timer_reference.start(time_sec)
	show()

	aftertext = aftertext_string

	running_timer = true
