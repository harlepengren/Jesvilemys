extends Control


@onready var timer_reference = $'Timer'
@onready var title_reference = $'Title'

var display_time = 0.0
var fade_in_display_time = 0.0
var fade_out_display_time = 0.0

var section = -1


func _ready() -> void:
	self.modulate.a = 0.0

func _process(delta: float) -> void:
	if self.section == 0:
		self.modulate.a = 1.0 - self.timer_reference.time_left / self.fade_in_display_time
	elif self.section == 2:
		self.modulate.a = self.timer_reference.time_left / self.fade_out_display_time


func change_colors(text_color: Color, outline_color: Color) -> void:
	title_reference.label_settings.font_color = text_color
	title_reference.label_settings.outline_color = outline_color

func display_text(text: String, time: float=1.0, fade_in_time: float=0.5, fade_out_time: float=0.5) -> void:
	self.title_reference.text = text

	self.display_time = time
	self.fade_in_display_time = fade_in_time
	self.fade_out_display_time = fade_out_time

	self.section = 0
	self.timer_reference.start(self.fade_in_display_time)


func _on_timer_timeout() -> void:
	self.section += 1

	if self.section == 1:
		self.timer_reference.start(self.display_time)
	elif self.section == 2:
		self.timer_reference.start(self.fade_out_display_time)
