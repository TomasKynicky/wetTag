extends CharacterBody3D

const SPEED := 5.0
const SPRINT_MULT := 1.8
const JUMP_VELOCITY := 4.5

const SLIDE_MIN_SPEED := 6.0
const SLIDE_DURATION := 0.6
const SLIDE_FRICTION := 12.0

var _is_sliding: bool = false
var _slide_time: float = 0.0
var stamina: int = 1000

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var want_sprint := Input.is_action_pressed("sprint")
	var input_dir := Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if _is_sliding:
		_slide_time += delta
		var horiz := Vector2(velocity.x, velocity.z)
		horiz = horiz.move_toward(Vector2.ZERO, SLIDE_FRICTION * delta)
		velocity.x = horiz.x
		velocity.z = horiz.y
		if _slide_time >= SLIDE_DURATION or horiz.length() < 0.5 or not is_on_floor():
			_is_sliding = false

	else:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if is_on_floor():
			var max_speed := SPEED * (SPRINT_MULT if want_sprint else 1.0)

			if direction != Vector3.ZERO:
				velocity.x = direction.x * max_speed
				velocity.z = direction.z * max_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, SPEED)
				velocity.z = move_toward(velocity.z, 0.0, SPEED)

			if Input.is_action_just_pressed("crouch") and want_sprint:
				var horiz_speed := Vector2(velocity.x, velocity.z).length()
				if horiz_speed >= SLIDE_MIN_SPEED:
					_is_sliding = true
					_slide_time = 0.0
					velocity.y = 0.0

	move_and_slide()
