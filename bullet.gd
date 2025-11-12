# bullet.gd
extends RigidBody3D

@export var speed: float = 180.0
@export var lifetime: float = 8.0
@export var stun_duration: float = 1.5
@export var projectile_group: String = "projectile"
@export var grace_time: float = 0.08
@export var enable_mask_after_grace: int = 1
@export var collision_layer_bits: int = 1
@export var use_gravity: bool = true
@export var mass_override: float = 0.05
@export var linear_damp_override: float = 0.0
@export var angular_damp_override: float = 0.0

var direction: Vector3 = Vector3(0, 0, -1)
var shooter: Node3D = null
var _t: float = 0.0
var _grace: float = 0.0
var _trail: GPUParticles3D

func set_shooter(n: Node3D) -> void:
	shooter = n

func configure(dir: Vector3, spd: float, life: float, stun: float) -> void:
	direction = dir.normalized()
	speed = spd
	lifetime = life
	stun_duration = stun

func _ready() -> void:
	if not is_in_group(projectile_group):
		add_to_group(projectile_group)

	freeze = false
	can_sleep = false
	sleeping = false

	gravity_scale = 1.0 if use_gravity else 0.0
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8

	collision_layer = 0
	collision_mask = 0

	mass = mass_override
	linear_damp = linear_damp_override
	angular_damp = angular_damp_override

	linear_velocity = direction * speed
	apply_impulse(direction * speed * mass)

	body_entered.connect(_on_body_entered)

	_grace = grace_time

	_trail = _make_trail()
	add_child(_trail)
	_trail.emitting = true

func _physics_process(delta: float) -> void:
	_t += delta

	if sleeping:
		PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_SLEEPING, false)

	if _grace > 0.0:
		_grace -= delta
		if _grace <= 0.0:
			collision_layer = collision_layer_bits
			collision_mask = enable_mask_after_grace

	if _t >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if shooter != null and (body == shooter or shooter.is_ancestor_of(body)):
		return
	if body.is_in_group(projectile_group):
		return
	if body.is_in_group("player") and body.has_method("stun"):
		body.stun(stun_duration)
	queue_free()

func _make_trail() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 64
	p.lifetime = 0.25
	p.one_shot = false
	p.preprocess = 0.0
	var m := ParticleProcessMaterial.new()
	m.gravity = Vector3(0, 0, 0)
	m.initial_velocity_min = 0.0
	m.initial_velocity_max = 0.5
	m.direction = Vector3(0, 0, 0)
	m.scale_curve = Curve.new()
	m.scale_curve.add_point(0.0, 0.8)
	m.scale_curve.add_point(1.0, 0.0)
	p.process_material = m
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.08, 0.08)
	p.draw_pass_1 = mesh
	p.local_coords = false
	return p
