extends RayCast3D
class_name Wheel

@export var wheel_radius: float = 0.15
@export var is_front_wheel: bool = false

@export var spring_strength: float = 2000
@export var spring_damping: float = 300

@export var grip: float = 1
@export var mass: float = 1

@onready var spring_resting_length: float = target_position.length()

@onready var mesh: Node3D = $MeshInstance3D

var _previous_spring_length: float = 0

# TODO: linearly interpolate wheel position

func _ready():
	# Ensure that raycasts are updated as early as possible each frame
	process_physics_priority = -5

func add_collision_exception(collision_object: CollisionObject3D) -> void:
	add_exception(collision_object)

func apply_forces(car: Car, delta: float) -> void:
	if not is_colliding():
		return
	var collision_point: Vector3 = get_collision_point()
	apply_suspension(car, collision_point, delta)
	apply_acceleration(car, collision_point)
	#apply_friction(car, collision_point, delta)
	#apply_steering(car, collision_point, delta)

func apply_acceleration(car: Car, collision_point: Vector3) -> void:
	if is_front_wheel:
		return
		
	var acceleration_direction: Vector3 = global_basis.z
	var torque: float = car.input.y * car.engine_power

	var acceleration_force: Vector3 = acceleration_direction * torque
	
	car.apply_force(acceleration_force, collision_point - car.global_position)
	
	DebugDraw3D.draw_arrow(collision_point, collision_point + acceleration_force * 0.002, Color(0, 0, 1,), 0.05, true)

func apply_suspension(car: Car, collision_point: Vector3, delta: float) -> void:
	var spring_direction: Vector3 = global_basis.y
	
	# Calculate spring length and clamp within valid range
	var spring_length: float = clamp(global_position.distance_to(collision_point), 0, spring_resting_length)
	
	# Calculate spring velocity for damping
	var spring_velocity: float = (spring_length - _previous_spring_length) / delta
	
	_previous_spring_length = spring_length

	# Calculate and apply forces
	var spring_force: float = (1.0 - spring_length / spring_resting_length) * spring_strength
	var damping_force: float = -spring_velocity * spring_damping

	var suspension_force: Vector3 = spring_direction * (spring_force + damping_force)
	
	#DebugDraw3D.draw_sphere(force_application_point, 0.1)
	
	car.apply_force(suspension_force, collision_point - car.global_position)
	
	# Adjust visuals
	DebugDraw3D.draw_arrow(collision_point, collision_point + suspension_force * 0.002, Color(0, 1, 0,), 0.05, true)
	mesh.position.y = -spring_length + wheel_radius

func apply_steering(car: Car, collision_point: Vector3, delta: float) -> void:
	var steering_direction: Vector3 = global_basis.x
	var wheel_velocity = car.get_point_velocity(collision_point)
	
	var steering_velocity: float = steering_direction.dot(wheel_velocity)
	
	var desired_acceleration = -steering_velocity * grip
	
	var steering_force = steering_direction * mass * desired_acceleration
	
	DebugDraw3D.draw_arrow(collision_point, collision_point + steering_force * 0.002, Color(1, 0, 0,), 0.05, true)
	
	car.apply_force(steering_force, collision_point)


#func apply_z_force(collision_point):
	#var dir: Vector3 = global_basis.z
	#var state := PhysicsServer3D.body_get_direct_state( car.get_rid() )
	#var tire_world_vel := state.get_velocity_at_local_position( global_position - car.global_position )
	#var z_force = dir.dot(tire_world_vel) * car.mass / 10
	#
	#car.apply_force(-dir * z_force, collision_point - car.global_position)
	
