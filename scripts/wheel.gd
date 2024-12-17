extends Node3D
class_name Wheel

@export var debug: bool = false

@export var wheel_radius: float = 0.15
@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var wheel_mass: float = 5

@export var is_front_wheel: bool = false

@export var spring_strength: float = 1500
@export var spring_damping: float = 300

@export var grip: Curve

@onready var shape_cast: ShapeCast3D = $ShapeCast3D
@onready var spring_resting_length: float = shape_cast.target_position.length()
@onready var mesh: Node3D = $MeshInstance3D

var _previous_spring_length: float

# TODO: add a wheel velocity

# TODO: linearly interpolate wheel position

func _ready():
	# Ensure that raycast is updated as early as possible each frame
	process_physics_priority = -100
	print(spring_resting_length)
	_previous_spring_length = spring_resting_length
	_update_mesh_position(1)

func add_collision_exception(collision_object: CollisionObject3D):
	shape_cast.add_exception(collision_object)

func _process(delta):
	_update_mesh_position(delta)

func apply_forces(car: Car, delta: float) -> void:
	if not shape_cast.is_colliding():
		_previous_spring_length = spring_resting_length
		return
	var collision_point: Vector3 = shape_cast.get_collision_point(0)
	apply_suspension(car, collision_point, delta)
	apply_acceleration(car, collision_point)
	apply_steering(car, collision_point, delta)

func apply_acceleration(car: Car, collision_point: Vector3) -> void:
	if is_front_wheel:
		return
	
	var acceleration_direction: Vector3 = global_basis.z
	var car_speed = abs(car.linear_velocity.dot(car.global_basis.z))
	var speed_normalized = clamp(car_speed / car.top_speed, 0, 1)
	print(car.engine_power.sample(speed_normalized))
	
	#print(speed_normalized)
	var torque: float = car.acceleration_input * car.engine_power.sample(speed_normalized)

	car.apply_force(acceleration_direction * torque, collision_point - car.global_position)
	
	if debug:
		DebugDraw3D.draw_arrow(collision_point, collision_point + acceleration_direction * torque * 0.002, Color(0, 0, 1,), 0.05, true)

func apply_suspension(car: Car, collision_point: Vector3, delta: float) -> void:
	var spring_direction: Vector3 = global_basis.y
	
	# Calculate spring length and clamp within valid range
	#print(shape_cast.get_closest_collision_safe_fraction() * spring_resting_length)
	var spring_length: float = shape_cast.get_closest_collision_unsafe_fraction() * spring_resting_length
	
	# Calculate spring velocity for damping
	var spring_velocity: float = (spring_length - _previous_spring_length) / delta
	
	_previous_spring_length = spring_length

	# Calculate and apply forces
	
	var spring_force: float = (1.0 - spring_length / spring_resting_length) * spring_strength
	var damping_force: float = -spring_velocity * spring_damping

	var suspension_force: Vector3 = spring_direction * (spring_force + damping_force)
	
	# DebugDraw3D.draw_sphere(collision_point, 0.5)
	
	car.apply_force(suspension_force, collision_point - car.global_position)
	
	if debug:
		DebugDraw3D.draw_arrow(collision_point, collision_point + suspension_force * 0.002, Color(0, 1, 0,), 0.05, true)

func apply_steering(car: Car, collision_point: Vector3, delta: float) -> void:
	var forward_direction: Vector3 = global_basis.z
	var steering_direction: Vector3 = global_basis.x
	var state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	var local_velocity := state.get_velocity_at_local_position(global_position - car.global_position)
	
	#DebugDraw3D.draw_arrow(collision_point, collision_point + forward_direction, Color(1, 0, 0,), 0.05, true)
	
	var current_grip: float = 1
	if not is_zero_approx(local_velocity.length()):
		var alignment: float = abs(forward_direction.dot(local_velocity.normalized()))
		#DebugDraw3D.draw_arrow(collision_point, collision_point + forward_direction, Color(1, 0, 0,), 0.05, true)
		#DebugDraw3D.draw_arrow(collision_point, collision_point + velocity_direction, Color(0, 1, 0,), 0.05, true)
		current_grip = grip.sample(alignment)
	
	var lateral_velocity: float = steering_direction.dot(local_velocity)
	
	var steering_acceleration: float = -lateral_velocity * current_grip / delta

	car.apply_force(steering_direction * wheel_mass * steering_acceleration, collision_point - car.global_position)
	
	# temporary mesh rotation
	mesh.rotation.x += local_velocity.dot(global_basis.z) * 0.1
	
	#if debug:
		#DebugDraw3D.draw_arrow(collision_point, collision_point + steering_force * 0.002, Color(1, 0, 0,), 0.05, true)

func _update_mesh_position(delta: float = 1):
	if delta >= 1:
		mesh.position.y = -spring_resting_length + wheel_radius
		return
	mesh.position.y = lerp(mesh.position.y, -_previous_spring_length + wheel_radius, 50 * delta)
	
