extends Camera3D


var timer_reference: Timer
var original_position = self.position

var is_shaking = false

var shaking_min: Vector3
var shaking_max: Vector3


func _ready() -> void:
	var timer = Timer.new()
	timer.one_shot = true
	
	timer.connect('timeout', self._on_timer_timeout)

	self.add_child(timer)
	timer_reference = timer

func _process(delta: float) -> void:
	if self.is_shaking:
		self.position.x = randf_range(self.shaking_min.x, self.shaking_max.x) + self.original_position.x
		self.position.y = randf_range(self.shaking_min.y, self.shaking_max.y) + self.original_position.y
		self.position.z = randf_range(self.shaking_min.z, self.shaking_max.z) + self.original_position.z


func start_shake(min: Vector3, max: Vector3, time: float):
	timer_reference.start(time)
	self.is_shaking = true

	self.shaking_min = min
	self.shaking_max = max


func _on_timer_timeout():
	self.is_shaking = false
