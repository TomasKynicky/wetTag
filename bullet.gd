extends Area3D

@export var life_time: float = 3.0
@export var damage: float = 10.0
@export var lock_time: float = 2.0

var _vel: Vector3 = Vector3.ZERO
var _alive: float = 0.0

func shoot(velocity: Vector3) -> void:
	_vel = velocity
	look_at(global_transform.origin + _vel.normalized(), Vector3.UP)

func _physics_process(delta: float) -> void:
	_alive += delta
	if _alive >= life_time:
		queue_free()
		return
	var from: Vector3 = global_transform.origin
	var to: Vector3 = from + _vel * delta
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	var hit: Dictionary = space.intersect_ray(query)
	if hit:
		var collider: Object = hit.get("collider")
		if collider:
			if collider.has_method("apply_damage"):
				collider.call("apply_damage", damage)
			if collider.has_method("lock_movement"):
				collider.call("lock_movement", lock_time)
		queue_free()
	else:
		global_transform.origin = to
