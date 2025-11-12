extends RigidBody3D

@export var lifetime: float = 5.0

func _ready() -> void:
	sleeping = false
	continuous_cd = true
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
