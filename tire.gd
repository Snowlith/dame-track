extends Node3D

@export var spring_rest_distance: float = 0.5
@export var spring_strength: float = 1
@export var spring_damping: float = 0.5

func _physics_process(delta: float) -> void:
	var spring_start_position: Vector3 = %RayCast3D.global_position
	DebugDraw3D.draw_position(Transform3D(Basis(), spring_start_position))
	
	var spring_direction: Vector3 = %RayCast3D.global_basis.y
	#DebugDraw3D.draw_arrow(origin, origin + spring_dir)
	
	var tire_velocity: Vector3 = get_point_velocity(spring_start_position)
	DebugDraw3D.draw_arrow(spring_start_position, spring_start_position + tire_velocity)
	
	if %RayCast3D.is_colliding():
		var spring_end_position = %RayCast3D.get_collision_point()
		DebugDraw3D.draw_position(Transform3D(Basis(), spring_end_position))
		
		var distance_along_spring: float = spring_start_position.distance_to(spring_end_position)
		var offset: float = spring_rest_distance - distance_along_spring
		
		var spring_velocity = spring_direction.dot(tire_velocity)
		
		var spring_force = offset * spring_strength - spring_velocity * spring_damping
		add_constant_force(spring_direction * spring_force, spring_start_position)
		
func get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_transform.origin)
