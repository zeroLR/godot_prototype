# warning-ignore:unused_signal
extends Actor

# warning-ignore:unused_signal
signal collect_coin

const FLOOR_DETECT_DISTANCE = 20.0

var state_machine
var run_speed = 80
var velocity = Vector2.ZERO

onready var platform_detector = $PlatformDetector
onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite
onready var sound_jump = $Jump


# Called when the node enters the scene tree for the first time.
func _ready():
	var camera: Camera2D = $Camera
	camera.custom_viewport = $"../.."
	yield(get_tree(), "idle_frame")
	camera.make_current()


func _physics_process(_delta):
	state_machine = $AnimationTree.get("parameters/StateMachine/playback")
	# Play jump sound
	if Input.is_action_just_pressed("jump") and is_on_floor():
		sound_jump.play()

	var direction = get_direction()

	var is_jump_interrupted = Input.is_action_just_released("jump") and _velocity.y < 0.0
	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)

	var snap_vector = Vector2.ZERO
	if direction.y == 0.0:
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE
	var is_on_platform = platform_detector.is_colliding()
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4, 0.9, false
	)

	if direction.x != 0:
		if direction.x > 0:
			sprite.scale.x = 1
		else:
			sprite.scale.x = -1
	var animation = get_input()


func get_direction():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1 if is_on_floor() and Input.is_action_just_pressed("jump") else 0
	)


func calculate_move_velocity(linear_velocity, direction, speed, is_jump_interrupted):
	var velocity = linear_velocity
	velocity.x = speed.x * direction.x
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
	if is_jump_interrupted:
		velocity.y *= 0.6
	return velocity


func get_input():
	print(_velocity)
	print(is_on_floor())
	if is_on_floor():
		if abs(_velocity.x) > 0.1:
			state_machine.travel("Run")
		else:
			state_machine.travel("Idle")
	else:
		if _velocity.y > -100:
			state_machine.travel("Fall")
		else:
			state_machine.start("Jump")
