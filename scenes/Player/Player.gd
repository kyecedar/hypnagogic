extends CharacterBody3D



@export var gravity       : float = 9.8 ## Speed player falls towards planet.
@export var max_fall_vel  : float = 21.0 ## Downward velocity.
@export var coyote_time   : float = 0.2 ## Time after player leaves floor where they can jump, not including time after jumping. In seconds.
@export var jump_prime    : float = 0.1 ## Time before player lands on floor where they can queue a jump. In seconds.
@export var upalign_speed : float = 5.0 ## How quick player rotates to align with [member CharacterBody3D.up_direction]. Higher = quicker.

@export_subgroup("Speed", "speed_")
@export var speed_walk : float = 4.0
@export var speed_run  : float = 7.0

@export_subgroup("Acceleration", "accel_")
@export var accel_floor : float = 32.0 ## Lower = slippery.
@export var accel_air   : float = 4.0 ## Lower = less control.

@export_subgroup("Friction", "friction_")
@export var friction_ground : float = 12.8 ## Higher = more friction.
@export var friction_air    : float = 2.4 ## Higher = more friction.

@export_subgroup("Look", "look_")
@export var look_min_angle    : float = -85.0 ## In degrees.
@export var look_max_angle    : float =  88.0 ## In degrees.
@export var look_swerve_angle : float =  30.0 ## In degrees. How far left or right the player can turn before it also turns the mesh.
@export var look_swerve_speed : float =   4.0 ## How quickly the player mesh rotates. Higher = quicker.
@export var look_swerve_time  : float =   2.0 ## In seconds. How long until the mesh turns to face forward.

@export_subgroup("Jump", "jump_")
@export var jump_velocity         : float = 5.5 ## Velocity added to player when jumping.
@export var jump_charge_time      : float = 0.4 ## In seconds. Time it takes player to charge jump.
@export var jump_charge_air_drain : float = 0.2 ## Multiplied by delta. How quick to drain player's jump charge while in the air.

@onready var neck : Node3D = $neck
@onready var head : Node3D = $neck/head
@onready var camera : Camera3D = $neck/head/camera
@onready var mesh : Node3D = $placeholder
@onready var reachray : RayCast3D = $neck/head/camera/reachray
@onready var shootray : RayCast3D = $neck/head/camera/shootray

var mouse_sensitivity = ProjectSettings.get_setting("hypnagogic/player/mouse_sensitivity")

var lucidity   : float = 1.0 ## 1 is concious, 0 is unconcious.
var lucid      : bool  = true ## Does player have control?
var spacebound : bool  = false ## Is player in anti-gravity?

var speed : float = speed_walk ## Current player speed.
var jump_prime_timer  : float = 0.0 ## See [member jump_prime].
var jump_coyote_timer : float = 0.0 ## See [member coyote_time].
var jump_queued       : float = false ## 0 - 1. If player has queued jump. Dictates how high jump will be.
var jump_charge_timer : float = 0.0 ## See [member jump_charge_time].

var look_swerve_timer : float = 0.0 ## See [member look_swerve_time].

var bingus : bool = false ## TODO : TEMP TEMP TEMP



func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if lucid:
		_handleMove(delta)
	
	_doMove(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if lucid:
			_handleLook(event)
	elif event is InputEventKey:
		if Input.is_action_just_pressed("sprintward"):
			if bingus:
				up_direction = Vector3.UP
			else:
				up_direction = Vector3.FORWARD
			
			bingus = !bingus
		elif Input.is_action_just_pressed("capture"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE



func _handleLook(event: InputEventMouseMotion) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	neck.rotate_y(-event.relative.x * (mouse_sensitivity.x / 1000))
	head.rotation.x = clamp(head.rotation.x + (-event.relative.y * (mouse_sensitivity.y / 1000)), deg_to_rad(look_min_angle), deg_to_rad(look_max_angle))
	
	if neck.rotation.y - mesh.rotation.y < deg_to_rad(-look_swerve_angle) or neck.rotation.y - mesh.rotation.y > deg_to_rad(look_swerve_angle):
		mesh.rotate_y(-event.relative.x * (mouse_sensitivity.x / 1000))
	
	# reset timer.
	look_swerve_timer = look_swerve_time

func _handleMove(delta: float) -> void:
	# jumping.
	if Input.is_action_pressed("jumpward"):
		jump_charge_timer = move_toward(jump_charge_timer, jump_charge_time, delta)
	
	if not spacebound:
		# coyote and jump prime.
		if is_on_floor():
			jump_coyote_timer = coyote_time
			
			if jump_prime_timer != 0.0:
				_queueJump()
			
			if Input.is_action_just_released("jumpward"):
				_queueJump()
		else:
			jump_coyote_timer = move_toward(jump_coyote_timer, 0.0, delta)
			jump_prime_timer = move_toward(jump_prime_timer, 0.0, delta)
			jump_charge_timer = move_toward(jump_charge_timer, 0.0, delta * jump_charge_air_drain)
			
			if Input.is_action_just_released("jumpward"):
				if jump_coyote_timer != 0.0:
					_queueJump()
				else:
					jump_prime_timer = jump_prime
		
		print(jump_charge_timer)
		
		# execute on queued jump.
		if jump_queued != 0.0:
			velocity += up_direction * (jump_velocity * jump_queued)
			jump_queued = 0.0
	
	var input_dir = Input.get_vector("leftward", "rightward", "forward", "backward")
	var direction = (neck.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, neck.rotation.y, look_swerve_speed * delta)
	
	if not spacebound:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, velocity.x * up_direction.x, friction_ground * delta)
			velocity.y = move_toward(velocity.y, velocity.y * up_direction.y, friction_ground * delta)
			velocity.z = move_toward(velocity.z, velocity.z * up_direction.z, friction_ground * delta)
		else:
			velocity.x = move_toward(velocity.x, velocity.x * up_direction.x, friction_air * delta)
			velocity.y = move_toward(velocity.y, velocity.y * up_direction.y, friction_air * delta)
			velocity.z = move_toward(velocity.z, velocity.z * up_direction.z, friction_air * delta)
		
		var abs_up : Vector3 = up_direction.abs()
		
		if is_on_floor(): # if is aligned with up direction, 
			velocity.x = move_toward(velocity.x, (direction.x * speed * (1 - abs_up.x)) + (velocity.x * abs_up.x), accel_floor * delta)
			velocity.y = move_toward(velocity.y, (direction.y * speed * (1 - abs_up.y)) + (velocity.y * abs_up.y), accel_floor * delta)
			velocity.z = move_toward(velocity.z, (direction.z * speed * (1 - abs_up.z)) + (velocity.z * abs_up.z), accel_floor * delta)
		else:
			velocity.x = move_toward(velocity.x, (direction.x * speed * (1 - abs_up.x)) + (velocity.x * abs_up.x), accel_air * delta)
			velocity.y = move_toward(velocity.y, (direction.y * speed * (1 - abs_up.y)) + (velocity.y * abs_up.y), accel_air * delta)
			velocity.z = move_toward(velocity.z, (direction.z * speed * (1 - abs_up.z)) + (velocity.z * abs_up.z), accel_air * delta)

func _queueJump() -> void:
	jump_coyote_timer = 0.0
	jump_prime_timer = 0.0
	jump_queued = jump_charge_timer / jump_charge_time
	jump_charge_timer = 0.0

func _doMove(delta: float) -> void:
	# gravity.
	if not is_on_floor():
		velocity -= up_direction * gravity * delta
	
	# rotate player.
	var rotupdir : Vector3 = up_direction.rotated(Vector3.RIGHT, deg_to_rad(90))
	rotation.x = lerp_angle(rotation.x, -atan2(rotupdir.y, rotupdir.z), upalign_speed * delta)
	rotupdir = up_direction.rotated(Vector3.FORWARD, deg_to_rad(90))
	rotation.z = lerp_angle(rotation.z, atan2(rotupdir.y, rotupdir.x), upalign_speed * delta)
	
	# timer countdown.
	look_swerve_timer = move_toward(look_swerve_timer, 0, delta)
	
	# rotate mesh.
	if neck.rotation.y - mesh.rotation.y != 0 and look_swerve_timer == 0:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, neck.rotation.y, look_swerve_speed * delta)
	
	move_and_slide()
