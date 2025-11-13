extends Node3D

@onready var area: Area3D = $Area3D
@onready var turret_body: Node3D = $Skeleton3D/TurretBody
@onready var turret_head: Node3D = $Skeleton3D/TurretBody/TurretHead
@onready var muzzle: Marker3D = $Skeleton3D/TurretBody/TurretHead/TurretCanon/Muzzle
@onready var fireTimer: Timer = $FireTimer

@export var target_group: String = "player"
@export var pitch_limits_deg: Vector2 = Vector2(-45.0, 45.0)
@export_range(-180.0, 180.0, 1.0) var yaw_offset_deg: float = 0.0
@export var invert_pitch: bool = false
@export var bulletScene: PackedScene
@export var bullet_speed: float = 60.0
@export var fire_cooldown_sec: float = 1.5

var canShootTimer: bool = true
var _target: Node3D = null

func _ready() -> void:
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)

	fireTimer.one_shot = true
	fireTimer.wait_time = fire_cooldown_sec
	fireTimer.timeout.connect(_on_timer_timeout)

func _physics_process(_delta: float) -> void:
	for b in area.get_overlapping_bodies():
		if b.is_in_group(target_group):
			_target = b
			var aimed := aim(_target.global_transform.origin)
			if aimed and canShootTimer:
				shoot()
				canShootTimer = false
				fireTimer.start()
			break

func _on_area_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		_target = body

func _on_area_body_exited(body: Node) -> void:
	if body == _target:
		_target = null

func aim(target_pos: Vector3) -> bool:
	var body_pos: Vector3 = turret_body.global_transform.origin
	var to: Vector3 = target_pos - body_pos

	var desired_yaw: float = atan2(to.x, to.z) + deg_to_rad(yaw_offset_deg)
	turret_body.rotation.y = lerp_angle(turret_body.rotation.y, desired_yaw, 0.15)
	var dir_local: Vector3 = turret_head.to_local(target_pos)
	var desired_pitch: float = -atan2(dir_local.y, dir_local.z)
	if invert_pitch:
		desired_pitch = -desired_pitch

	desired_pitch = clamp(
		desired_pitch,
		deg_to_rad(pitch_limits_deg.x),
		deg_to_rad(pitch_limits_deg.y)
	)
	var yaw_err: float = abs(wrapf(desired_yaw - turret_body.rotation.y, -PI, PI))
	return yaw_err < 0.01

func _get_player() -> Node3D:
	var list := get_tree().get_nodes_in_group(target_group)
	if list.size() == 0:
		return null
	return list[0] as Node3D

func shoot() -> void:
	var player := _get_player()
	if bulletScene == null:
		return

	var bullet := bulletScene.instantiate() as RigidBody3D
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = muzzle.global_transform

	var dir: Vector3
	if player and is_instance_valid(player):
		dir = (player.global_transform.origin - muzzle.global_transform.origin).normalized()
	else:
		dir = -muzzle.global_transform.basis.z

	bullet.linear_velocity = dir * bullet_speed
	bullet.sleeping = false
	bullet.continuous_cd = true
	bullet.contact_monitor = true

func _on_timer_timeout() -> void:
	canShootTimer = true
