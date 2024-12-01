extends RigidBody3D

@export var rest_distance: float = .5

func _physics_process(delta: float) -> void:
	var origin = %RayCast3D.global_position
	DebugDraw3D.draw_position(Transform3D(Basis(), origin))
	var spring_dir = %RayCast3D.global_basis.y
	#DebugDraw3D.draw_arrow(origin, origin + spring_dir)
	
	var tire_world_velocity = get_point_velocity(origin)
	DebugDraw3D.draw_arrow(origin, origin + tire_world_velocity)
	if %RayCast3D.is_colliding():
		print("colliding")
		var point = %RayCast3D.get_collision_point()
		print(point)
		DebugDraw3D.draw_position(Transform3D(Basis(), point))
		var distance = origin.distance_to(point)
		var offset: float = rest_distance - distance
		print(distance)
func get_point_velocity (point :Vector3)->Vector3:
	return linear_velocity + angular_velocity.cross(point - global_transform.origin)
