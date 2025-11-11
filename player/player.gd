extends CharacterBody3D

const SPEED := 30.0
const SPRINT_MULT := 1.8
const JUMP_VELOCITY := 4.5

const SLIDE_MIN_SPEED := 6.0
const SLIDE_DURATION := 0.6
const SLIDE_FRICTION := 12.0

@export var mouse_sensitivity: float = 0.003

var _is_sliding: bool = false
var _slide_time: float = 0.0
var stamina: int = 1000

@onready var camera: Camera3D = $Camera3D
var _pitch: float = 0.0

var _move_lock: float = 0.0

func lock_movement(duration: float) -> void:
	_move_lock = max(_move_lock, duration)

func _ready() -> void:
	add_to_group("player")
	add_to_group("target_group")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-80.0), deg_to_rad(80.0))
		camera.rotation.x = _pitch
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _move_lock > 0.0:
		_move_lock -= delta
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		move_and_slide()
		return

	var want_sprint: bool = Input.is_action_pressed("sprint")
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if _is_sliding:
		_slide_time += delta
		var horiz: Vector2 = Vector2(velocity.x, velocity.z)
		horiz = horiz.move_toward(Vector2.ZERO, SLIDE_FRICTION * delta)
		velocity.x = horiz.x
		velocity.z = horiz.y
		if _slide_time >= SLIDE_DURATION or horiz.length() < 0.5 or not is_on_floor():
			_is_sliding = false
	else:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if is_on_floor():
			var max_speed: float = SPEED * (SPRINT_MULT if want_sprint else 1.0)
			if direction != Vector3.ZERO:
				velocity.x = direction.x * max_speed
				velocity.z = direction.z * max_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, SPEED)
				velocity.z = move_toward(velocity.z, 0.0, SPEED)
			if Input.is_action_just_pressed("crouch") and want_sprint:
				var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
				if horiz_speed >= SLIDE_MIN_SPEED:
					_is_sliding = true
					_slide_time = 0.0
					velocity.y = 0.0

	move_and_slide()
