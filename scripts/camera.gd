extends Camera3D

@export var move_speed: float = 100.0
@export var mouse_sensitivity: float = 0.002

var yaw: float = 0.0
var pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw   -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		rotation = Vector3(pitch, yaw, 0.0)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(delta: float) -> void:
	var dir := Vector3.ZERO

	if Input.is_action_pressed("ui_up"):
		dir -= transform.basis.z   # dopředu
	if Input.is_action_pressed("ui_down"):
		dir += transform.basis.z   # dozadu
	if Input.is_action_pressed("ui_left"):
		dir -= transform.basis.x   # doleva
	if Input.is_action_pressed("ui_right"):
		dir += transform.basis.x   # doprava

	if dir != Vector3.ZERO:
		dir = dir.normalized()
		global_position += dir * move_speed * delta
