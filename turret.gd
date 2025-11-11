extends Node3D

@onready var area: Area3D = $Area3D
@onready var turret_head: Node3D = $Skeleton3D/TurretHead
@onready var turret_cannon: Node3D = $Skeleton3D/TurretHead/TurretCanon
@onready var muzzle: Marker3D = $Skeleton3D/TurretHead/TurretCanon/Muzzle

@export var bullet_scene: PackedScene
@export var fire_rate_hz: float = 2.0
@export var bullet_speed: float = 60.0
@export var aim_cone_deg: float = 45.0   # větší kužel → nemusí mířit 100% přesně

@export var target_group := "player"
@export var pitch_limits_deg := Vector2(-45.0, 45.0)
@export_range(-180.0, 180.0, 1.0) var yaw_offset_deg := 0.0
@export var invert_pitch := false

var _target: Node3D = null
var _cooldown: float = 0.0

func _ready() -> void:
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	area.monitoring = true
	area.monitorable = true

func _physics_process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta)
	_refresh_target_if_needed()

	if _is_valid_target(_target):
		_aim_now(_target.global_transform.origin)
		if _can_fire_now():
			_fire()

func _on_area_body_entered(body: Node) -> void:
	if body is Node3D and (target_group == "" or body.is_in_group(target_group)):
		_target = body as Node3D

func _on_area_body_exited(body: Node) -> void:
	if body == _target:
		_target = null

func _refresh_target_if_needed() -> void:
	if _is_valid_target(_target):
		return

	_target = null
	var best: Node3D = null
	var best_dist: float = INF

	for b in area.get_overlapping_bodies():
		if b is Node3D and (target_group == "" or b.is_in_group(target_group)):
			var d: float = (b.global_transform.origin - turret_head.global_transform.origin).length()
			if d < best_dist:
				best = b
				best_dist = d

	_target = best

func _is_valid_target(n: Node3D) -> bool:
	return n != null and is_instance_valid(n) and n.is_inside_tree()

func _aim_now(target_pos: Vector3) -> void:
	var head_pos: Vector3 = turret_head.global_transform.origin
	var to: Vector3 = target_pos - head_pos

	# YAW – otáčení hlavy
	var yaw: float = atan2(to.x, to.z) + deg_to_rad(yaw_offset_deg)
	turret_head.rotation.y = yaw
	turret_head.rotation.x = 0.0
	turret_head.rotation.z = 0.0

	# PITCH – sklon kanónu
	var dir_local: Vector3 = turret_head.to_local(target_pos)
	var pitch: float = -atan2(dir_local.y, dir_local.z)
	if invert_pitch:
		pitch = -pitch
	pitch = clamp(pitch, deg_to_rad(pitch_limits_deg.x), deg_to_rad(pitch_limits_deg.y))

	turret_cannon.rotation.x = pitch
	turret_cannon.rotation.y = 0.0
	turret_cannon.rotation.z = 0.0

func _can_fire_now() -> bool:
	if _cooldown > 0.0 or _target == null:
		return false

	# směr z hlavně
	var forward: Vector3 = -muzzle.global_transform.basis.z
	var to_target: Vector3 = (_target.global_transform.origin - muzzle.global_transform.origin).normalized()

	# TADY byl ten error → explicitně float + clampf
	var dot: float = clampf(forward.dot(to_target), -1.0, 1.0)
	var ang: float = rad_to_deg(acos(dot))

	# když nechceš řešit přesnost, můžeš tohle úplně vypnout:
	# return true

	return ang <= aim_cone_deg

func _fire() -> void:
	if bullet_scene == null:
		return

	var bullet: Node3D = bullet_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(bullet)

	# spawn přesně v pozici a rotaci muzzle
	bullet.global_transform = muzzle.global_transform

	var dir: Vector3 = -muzzle.global_transform.basis.z
	if bullet.has_method("shoot"):
		bullet.call("shoot", dir * bullet_speed)

	_cooldown = 1.0 / max(fire_rate_hz, 0.001)
