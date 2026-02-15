extends CharacterBody3D


@export_category('Speed')
@export var top_speed = 5.0
@export var speed_increase = 0.6
@export var speed_decrease = 1.0
@export var turn_speed = 1.0

@export_category('Jumping')
@export var jump_velocity = 4.5

@export var max_air_time = 10
var air_time = self.max_air_time + 1

@onready var model_reference = $'Model'

var last_direction = Vector2(0, 0)
var was_airborn = true


func handle_gravity(delta: float) -> void:
	if self.is_on_floor():
		self.air_time = 0

		if self.was_airborn:
			self.was_airborn = false
	else:
		self.velocity += get_gravity() * delta
		self.air_time += 1

		if self.air_time == 50:
			self.was_airborn = true

func handle_jump() -> void:
	if !Input.is_action_just_pressed('player_jump'):
		return
	if !(self.is_on_floor() or self.air_time <= self.max_air_time):
		return

	self.velocity.y = self.jump_velocity
	self.air_time = self.max_air_time + 1

func handle_movement() -> void: # Get the input direction and handle the movement/deceleration
	var direction := Input.get_axis('player_move_left', 'player_move_right')
	if !direction:
		self.velocity.x = move_toward(self.velocity.x, 0, self.speed_decrease)
		return

	if self.last_direction.x != direction and self.last_direction.x != 0:
		self.velocity.x = move_toward(self.velocity.x, direction * self.top_speed, self.turn_speed)
		self.last_direction.x = direction

		return

	self.velocity.x = move_toward(self.velocity.x, direction * self.top_speed, self.speed_increase)
	self.last_direction.x = direction

func _physics_process(delta: float) -> void:
	self.handle_gravity(delta)

	self.handle_jump()
	self.handle_movement()

	self.move_and_slide()
