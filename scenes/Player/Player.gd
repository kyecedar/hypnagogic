extends CharacterBody3D



@export var gravity       : float = 9.8 ## Speed player falls towards planet.
@export var max_fall_vel  : float = 21.0 ## Downward velocity.
@export var jump_velocity : float = 5.0 ## Velocity added to player when jumping.
@export var coyote_time   : float = 0.1 ## Time after player leaves floor where they can jump, not including time after jumping. In seconds.
@export var jump_prime    : float = 0.1 ## Time before player lands on floor where they can queue a jump. In seconds.
@export var upalign_speed : float = 5.0 ## How quick player rotates to align with [member CharacterBody3D.up_direction]. Higher = quicker.

@export_subgroup("Speed", "speed_")
@export var speed_default : float = 5.0

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
@export var look_swerve_timer : float =   3.0 ## In seconds. How long until the mesh turns to face forward.

@onready var neck : Node3D = $neck
@onready var head : Node3D = $neck/head
@onready var camera : Camera3D = $neck/head/camera

var mouse_sensitivity = ProjectSettings.get_setting("hypnagogic/player/mouse_sensitivity")

var lucidity   : float = 1.0 ## 1 is concious, 0 is unconcious.
var lucid      : bool  = true ## Does player have control?
var spacebound : bool  = false ## Is player in anti-gravity?

var speed : float = speed_default ## Current player speed.
var jump_prime_timer  : float = 0.0 ## See [member jump_prime].
var jump_coyote_timer : float = 0.0 ## See [member coyote_time].
var jump_queued       : bool = false ## If player has queued jump.

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

func _handleMove(delta: float) -> void:
	# jumping.
	if not spacebound:
		# coyote and jump prime.
		if is_on_floor():
			jump_coyote_timer = coyote_time
			
			if jump_prime_timer != 0:
				jump_coyote_timer = 0 # could make this a function, but eh eh.
				jump_prime_timer = 0
				jump_queued = true
			
			if Input.is_action_just_pressed("jumpward"):
				jump_coyote_timer = 0
				jump_prime_timer = 0
				jump_queued = true
		else:
			jump_coyote_timer = move_toward(jump_coyote_timer, 0, delta)
			jump_prime_timer = move_toward(jump_prime_timer, 0, delta)
			
			if Input.is_action_just_pressed("jumpward"):
				if jump_coyote_timer != 0:
					jump_coyote_timer = 0
					jump_prime_timer = 0
					jump_queued = true
				else:
					jump_prime_timer = jump_prime
		
		# execute on queued jump.
		if jump_queued:
			velocity += up_direction * jump_velocity
			jump_queued = false
	
	var input_dir = Input.get_vector("leftward", "rightward", "forward", "backward")
	var direction = (neck.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
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

func _doMove(delta: float) -> void:
	# gravity.
	if not is_on_floor():
		velocity -= up_direction * gravity * delta
	
	#transform = transform.interpolate_with(hypnagogic.alignWithY(transform, up_direction), upalign_speed * delta)
	Vector3().rotated(Vector3.RIGHT, deg_to_rad(-90))
	
	# rotate player.
	var rotupdir : Vector3 = up_direction.rotated(Vector3.RIGHT, deg_to_rad(90))
	rotation.x = lerp_angle(rotation.x, -atan2(rotupdir.y, rotupdir.z), upalign_speed * delta)
	rotupdir = up_direction.rotated(Vector3.FORWARD, deg_to_rad(90))
	rotation.z = lerp_angle(rotation.z, atan2(rotupdir.y, rotupdir.x), upalign_speed * delta)
	print(atan2(rotupdir.y, rotupdir.z))
	
	move_and_slide()
