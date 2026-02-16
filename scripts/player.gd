extends CharacterBody3D


@export var disable_movement = false
@export var disable_jump = false
@export var disable_punch = false

@export_category('Speed')
@export var top_speed = 4.0
@export var speed_increase = 0.6
@export var speed_decrease = 1.0
@export var turn_speed = 1.0

@export_category('Jumping')
@export var jump_velocity = 4.8

@export var max_air_time = 10
var air_time = self.max_air_time + 1

@onready var model_reference = $'Model'
@onready var animation_reference = $'Model/AnimationPlayer'
@onready var punch_area_reference = $'Area3D'

@onready var world_reference = $'../'

var last_direction = Vector2(0, 0)
var was_airborn = true

var animation_states = {
	'on_floor': true,
	'walking': false,
	'punch': 0
}

var can_punch_hit = false


func handle_gravity(delta: float) -> void:
	var on_floor = self.is_on_floor()
	self.animation_states.on_floor = on_floor

	if on_floor:
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
	if !direction or self.disable_movement:
		self.animation_states.walking = false
		self.velocity.x = move_toward(self.velocity.x, 0, self.speed_decrease)
		return

	model_reference.rotation.y = move_toward(model_reference.rotation.y, direction * 1.5, 0.2)
	self.animation_states.walking = true

	if self.last_direction.x != direction and self.last_direction.x != 0:
		self.velocity.x = move_toward(self.velocity.x, direction * self.top_speed, self.turn_speed)
		self.last_direction.x = direction

		return

	self.velocity.x = move_toward(self.velocity.x, direction * self.top_speed, self.speed_increase)
	self.last_direction.x = direction

	punch_area_reference.position.x = last_direction.x * 0.3

func use_item(item_soul):
	if item_soul == 'none': pass
	else:
		world_reference.title_board_reference.change_colors(Color(0.9, 0.6, 0.7, 1.0), Color(0.5, 0.0, 0.2, 1.0))
		world_reference.title_board_reference.display_text('Invalid item soul: ' + item_soul)

		push_error('Invalid item soul: ' + item_soul)

func handle_punch():
	if !Input.is_action_just_pressed('player_punch'):
		if self.animation_states.punch > 0:
			self.animation_states.punch -= 1

		return

	for punchable_body in punch_area_reference.get_overlapping_bodies():
		if punchable_body is not CharacterBody3D: continue
		if punchable_body == self: continue

		var distance_x = (punchable_body.position - self.position).x
		distance_x = distance_x / abs(distance_x)

		punchable_body.velocity = Vector3(distance_x * 8.0, 1.0, 0.0)

	for punchable_area in punch_area_reference.get_overlapping_areas():
		var area_parent = punchable_area.get_parent()

		if 'item_id' not in area_parent: continue # Check if item
		if !area_parent.punch(): continue # Run punch function

		use_item(world_reference.current_item_souls[area_parent.item_id])

	self.animation_states.punch = 25
	model_reference.rotation.y = self.last_direction.x * 1.5

func _physics_process(delta: float) -> void:
	self.handle_gravity(delta)

	if !self.disable_jump:
		self.handle_jump()
	self.handle_movement()
	if !self.disable_punch:
		self.handle_punch()

	self.move_and_slide()


func handle_animation() -> void:
	if self.animation_states.punch:
		if self.last_direction.x == -1:
			animation_reference.play('attack-melee-left')
			return
		if self.last_direction.x == 1:
			animation_reference.play('attack-melee-right')
			return

	if !self.animation_states.on_floor:
		animation_reference.play('jump')
		return

	if self.animation_states.walking:
		animation_reference.play('sprint')
		return

	animation_reference.play('idle')

func _process(delta: float) -> void:
	handle_animation()
