# turret.gd
extends Node3D

@onready var area: Area3D = $Area3D
@onready var turret_head: Node3D = $Skeleton3D/TurretHead
@onready var turret_cannon: Node3D = $Skeleton3D/TurretHead/TurretCanon
@onready var muzzle: Marker3D = $Skeleton3D/TurretHead/TurretCanon/Muzzle
@onready var fire_timer: Timer = $FireTimer

@export var target_group: String = "player"
@export var projectile_group: String = "projectile"
@export var pitch_limits_deg: Vector2 = Vector2(-45.0, 45.0)
@export_range(-180.0, 180.0, 1.0) var yaw_offset_deg: float = 0.0
@export var invert_pitch: bool = false
@export var bullet_scene: PackedScene
@export var fire_rate_hz: float = 3.0
@export var bullet_speed: float = 180.0
@export var bullet_lifetime_s: float = 8.0
@export var stun_duration_s: float = 1.5
@export var max_fire_distance: float = 500.0
@export var spawn_offset: float = 2.0

var _target: Node3D = null

func _update_fire_timer() -> void:
	var hz: float = max(fire_rate_hz, 0.1)
	fire_timer.wait_time = 1.0 / hz
	fire_timer.one_shot = false
	fire_timer.autostart = false

func _ready() -> void:
	area.monitoring = true
	area.monitorable = true
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	_update_fire_timer()
	if not fire_timer.timeout.is_connected(shoot):
		fire_timer.timeout.connect(shoot)
	fire_timer.stop()

func _physics_process(_delta: float) -> void:
	if not _is_valid_target(_target):
		for b in area.get_overlapping_bodies():
			if b is Node3D and not b.is_in_group(projectile_group) and (target_group == "" or (b as Node3D).is_in_group(target_group)):
				_target = b as Node3D
				break
	if _is_valid_target(_target):
		aim(_target.global_transform.origin)
		if fire_timer.is_stopped():
			fire_timer.start()
	else:
		if not fire_timer.is_stopped():
			fire_timer.stop()

func _on_area_body_entered(body: Node) -> void:
	if body.is_in_group(projectile_group):
		return
	if body is Node3D and (target_group == "" or body.is_in_group(target_group)):
		_target = body as Node3D
		if fire_timer.is_stopped():
			fire_timer.start()

func _on_area_body_exited(body: Node) -> void:
	if body.is_in_group(projectile_group):
		return
	if body == _target:
		_target = null
		if not fire_timer.is_stopped():
			fire_timer.stop()

func _is_valid_target(n: Node3D) -> bool:
	return n != null and is_instance_valid(n) and n.is_inside_tree()

func aim(target_pos: Vector3) -> void:
	var head_pos: Vector3 = turret_head.global_transform.origin
	var to: Vector3 = target_pos - head_pos
	var yaw: float = atan2(to.x, to.z) + deg_to_rad(yaw_offset_deg)
	turret_head.rotation = Vector3(0.0, yaw, 0.0)
	var dir_local: Vector3 = turret_head.to_local(target_pos)
	var pitch: float = -atan2(dir_local.y, dir_local.z)
	if invert_pitch:
		pitch = -pitch
	pitch = clamp(pitch, deg_to_rad(pitch_limits_deg.x), deg_to_rad(pitch_limits_deg.y))
	turret_cannon.rotation = Vector3(pitch, 0.0, 0.0)

func shoot() -> void:
	if not _is_valid_target(_target):
		if not fire_timer.is_stopped():
			fire_timer.stop()
		return
	if bullet_scene == null:
		return
	var dist: float = global_position.distance_to(_target.global_position)
	if dist > max_fire_distance:
		return

	var bullet := bullet_scene.instantiate()
	if bullet == null:
		return
	get_tree().current_scene.add_child(bullet)

	var muzzle_pos: Vector3 = muzzle.global_transform.origin
	var dir_to_target: Vector3 = (_target.global_transform.origin - muzzle_pos).normalized()
	if dir_to_target.length_squared() < 1e-6:
		dir_to_target = -turret_cannon.global_transform.basis.z.normalized()

	var spawn_pos: Vector3 = muzzle_pos + dir_to_target * spawn_offset
	bullet.global_transform = Transform3D(muzzle.global_transform.basis, spawn_pos)
	bullet.add_to_group(projectile_group)

	if bullet.has_method("set_shooter"):
		bullet.set_shooter(self)
	if bullet.has_method("configure"):
		bullet.configure(dir_to_target, bullet_speed, bullet_lifetime_s, stun_duration_s)

	_muzzle_flash()

func _muzzle_flash() -> void:
	var p := GPUParticles3D.new()
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.05
	m.initial_velocity_min = 0.0
	m.initial_velocity_max = 0.0
	m.scale_curve = Curve.new()
	m.scale_curve.add_point(0.0, 1.0)
	m.scale_curve.add_point(1.0, 0.0)
	p.process_material = m
	p.amount = 12
	p.lifetime = 0.06
	p.one_shot = true
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12)
	p.draw_pass_1 = mesh
	add_child(p)
	p.global_transform.origin = muzzle.global_transform.origin
	p.emitting = true
