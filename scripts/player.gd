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

@onready var punch_area_reference = $'Area3D'

@onready var world_reference = $'../'

var model_reference: Object
var animation_reference: Object

var last_direction = Vector2(0, 0)
var was_airborn = true

var animation_states = {
	'on_floor': true,
	'walking': false,
	'punch': 0
}

var can_punch_hit = false

var possible_skins = [
	'CharlieModel',
	'DaiseyModel',
	'EllenModel',
	'JuliusModel',
	'MaliaModel',
	'MarkModel',
	'RippleModel',
	'SebrinaModel',
	'StefanieModel',
	'VannesaModel'
]

# Synced display state - same model across multiplayer
var synced_skin_name: String = ''
@export var synced_model_rotation_y: float = 0.0
@export var synced_anim_on_floor: bool = true
@export var synced_anim_walking: bool = false
@export var synced_anim_punch: int = 0
var modifiers = {
	'freeze': 0.0,
	'faster': 0.0
}
 
var playing_alone:bool = false

func change_character_skin(skin_name: String):
	if model_reference: model_reference.hide()

	model_reference = self.get_node(skin_name)
	animation_reference = model_reference.get_node('AnimationPlayer')

	model_reference.show()

@rpc('any_peer', 'call_local', 'reliable')
func set_skin(skin_name: String):
	# Only accept this call from the server or from the node's own authority
	var sender = multiplayer.get_remote_sender_id()
	if sender != 1 and sender != name.to_int(): return
	
	synced_skin_name = skin_name
	if not multiplayer.is_server():
		change_character_skin(skin_name)

func _ready() -> void:
	if Globals.port == -1:
		playing_alone = true
	elif multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_new_peer_connected)
		return

	if is_multiplayer_authority():
		var chosen = possible_skins.pick_random()
		set_skin.rpc(chosen)
	
	get_node("/root/GameManager").rpc("register_name",Globals.player_name)

func _on_new_peer_connected(new_peer_id: int) -> void:
	if synced_skin_name == '': return
	set_skin.rpc_id(new_peer_id, synced_skin_name)

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

	self.velocity.y = self.jump_velocity + int(self.modifiers['faster'] != 0.0) * 2.0
	self.air_time = self.max_air_time + 1

func handle_movement() -> void: # Get the input direction and handle the movement/deceleration	
	if not model_reference: return
	if not speed_decrease: return
	
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

	self.velocity.x = move_toward(self.velocity.x, direction * (self.top_speed + int(self.modifiers['faster'] != 0.0) * 2.0), self.speed_increase)
	self.last_direction.x = direction

	punch_area_reference.position.x = last_direction.x * 0.3

func use_item(item_soul, item_location: Vector3):
	if item_soul == 'none': pass
	elif item_soul == 'explode':
		var distance_x = (item_location - self.position).x
		distance_x = distance_x / abs(distance_x)

		self.velocity = Vector3(distance_x * -16.0, 10.0, 0.0)
		world_reference.camera_reference.start_shake(Vector3(-0.1, -0.1, 0.0), Vector3(0.1, 0.1, 0.0), 0.15)

	elif item_soul == 'freeze':
		self.modifiers['freeze'] = 100.0

	elif item_soul == 'faster':
		self.modifiers['faster'] = 500.0

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

		if playing_alone:
			punchable_body.single_player_punched(Vector3(distance_x * 8.0, 1.0, 0.0))
			continue

		# Notify the server's GameManager about this hit
		var attacker_id = name.to_int()
		var victim_id = punchable_body.name.to_int()
		get_node("/root/GameManager").rpc_id(1, "register_hit", attacker_id, victim_id)

	for punchable_area in punch_area_reference.get_overlapping_areas():
		var area_parent = punchable_area.get_parent()

		if 'item_id' not in area_parent: continue # Check if item
		if !area_parent.punched(): continue # Run punch function

		use_item(world_reference.current_item_souls[area_parent.item_id], area_parent.position)

	self.animation_states.punch = 25
	model_reference.rotation.y = self.last_direction.x * 1.5

func _physics_process(delta: float) -> void:
	if not playing_alone and not is_multiplayer_authority(): return
	
	self.handle_gravity(delta)

	if !self.disable_jump:
		self.handle_jump()
	self.handle_movement()
	if !self.disable_punch:
		self.handle_punch()

	self.move_and_slide()
	
	# Sync animation data
	synced_model_rotation_y = model_reference.rotation.y if model_reference else 0.0
	synced_anim_on_floor = animation_states.on_floor
	synced_anim_walking = animation_states.walking
	synced_anim_punch = animation_states.punch
	
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func handle_modifiers() -> void:
	if self.modifiers['freeze'] != 0.0:
		self.modifiers['freeze'] -= 1.0

		if self.modifiers['freeze'] != 0.0:
			self.disable_movement = true
			self.disable_jump = true
		else:
			self.disable_movement = false
			self.disable_jump = false

	if self.modifiers['faster'] != 0.0:
		self.modifiers['faster'] -= 1.0


func handle_animation() -> void:
	var is_authority = is_multiplayer_authority() or playing_alone

	var anim_punch  = animation_states.punch   if is_authority else synced_anim_punch
	var anim_floor  = animation_states.on_floor if is_authority else synced_anim_on_floor
	var anim_walk   = animation_states.walking  if is_authority else synced_anim_walking
	var model_rot_y = (model_reference.rotation.y if model_reference else 0.0) if is_authority else synced_model_rotation_y

	# Apply synced rotation to the remote model
	if not is_authority and model_reference:
		model_reference.rotation.y = model_rot_y

	if anim_punch:
		if model_rot_y < 0:
			animation_reference.play('attack-melee-left')
			return
		if model_rot_y > 0:
			animation_reference.play('attack-melee-right')
			return

	if !anim_floor:
		animation_reference.play('jump')
		return

	if anim_walk:
		animation_reference.play('sprint')
		return

	animation_reference.play('idle')

func _process(_delta: float) -> void:
	if multiplayer.is_server() and !playing_alone:
		return
	if model_reference:
		handle_animation()
		handle_modifiers()


@rpc("any_peer", "call_local", "reliable")
func punched(knockback_strength: Vector3) -> bool:
	if multiplayer.get_remote_sender_id() != 1:
		# Must be sent from the server
		return false

	print("Punched: %s"%[knockback_strength])
	self.velocity = knockback_strength

	return true

func single_player_punched(knockback_strength: Vector3) -> bool:
	print("Punched: %s"%[knockback_strength])
	self.velocity = knockback_strength

	return true
