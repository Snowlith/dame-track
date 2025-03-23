extends Node3D
class_name Wheel

@export var show_debug_arrows: bool = false

@export var wheel_mesh_radius: float = 0.2
@export var is_front_wheel: bool = false
@export var spring_strength: float = 1500
@export var spring_damping: float = 300
@export var friction_coefficient: float = 0.5
@export var steering_strength: float = 200
@export var grip: Curve

@onready var ray_cast: RayCast3D = $RayCast3D
@onready var spring_resting_length: float = ray_cast.target_position.length()
@onready var mesh: Node3D = $MeshInstance3D

var _previous_spring_length: float
var _current_rotational_speed: float

func _ready():
	_previous_spring_length = spring_resting_length
	
	# Ensure that the ray cast is not a frame behind when applying forces
	ray_cast.process_physics_priority = -100
	
	# Reset the mesh position
	mesh.position.y = -spring_resting_length + wheel_mesh_radius
	
func _process(delta):
	mesh.position.y = lerp(mesh.position.y, -_previous_spring_length + wheel_mesh_radius, 50 * delta)
	mesh.rotation.x += _current_rotational_speed * delta

# Called by the car to avoid wheel-car collisions
func add_collision_exception(collision_object: CollisionObject3D) -> void:
	ray_cast.add_exception(collision_object)

func apply_forces(car: Car, delta: float) -> void:
	if not ray_cast.is_colliding():
		_previous_spring_length = spring_resting_length
		return
	
	var collision_point: Vector3 = ray_cast.get_collision_point()
	
	var suspension_force: Vector3 = _get_suspension_force(car, collision_point, delta)
	var acceleration_force: Vector3 = _get_acceleration_force(car)
	var steering_force: Vector3 = _get_steering_force(car, delta)
	var friction_force: Vector3 = _get_friction_force(car, delta, suspension_force)
	
	if show_debug_arrows:
		DebugDraw3D.draw_arrow(collision_point, collision_point + suspension_force * 0.005, Color.WEB_GREEN, 0.05, true)
		DebugDraw3D.draw_arrow(collision_point, collision_point + acceleration_force * 0.01, Color.BLUE, 0.05, true)
		DebugDraw3D.draw_arrow(collision_point, collision_point + steering_force * 0.005, Color.RED, 0.05, true)
		DebugDraw3D.draw_arrow(collision_point, collision_point + friction_force * 0.05, Color.YELLOW, 0.05, true)
		
	var net_force: Vector3 = suspension_force + acceleration_force + steering_force + friction_force
	# Apply the net force at the wheel position relative to the car
	car.apply_force(net_force, collision_point - car.global_position)

# Calculate the force the ray cast would apply if it were a damped spring
func _get_suspension_force(car: Car, collision_point: Vector3, delta: float) -> Vector3:
	var spring_direction: Vector3 = global_basis.y
	
	var spring_length: float = (collision_point - ray_cast.global_position).length()
	
	# Calculate the velocity of the spring which is important for damping
	var spring_velocity: float = (spring_length - _previous_spring_length) / delta
	
	# Store the current spring length for the next frame
	_previous_spring_length = spring_length

	var spring_force: float = (1.0 - spring_length / spring_resting_length) * spring_strength
	var damping_force: float = -spring_velocity * spring_damping

	return spring_direction * (spring_force + damping_force)

# Calculate acceleration or deceleration based on the player's input
func _get_acceleration_force(car: Car) -> Vector3:
	if is_front_wheel:
		return Vector3.ZERO
	
	var acceleration_direction: Vector3 = global_basis.z
	
	# Get the current speed compared to the top speed
	var car_speed: float = abs(car.linear_velocity.dot(car.global_basis.z))
	var speed_normalized: float = clamp(car_speed / car.top_speed, 0, 1)
	
	# Get the player's input and scale it by the engine power at the current speed
	var torque: float = -car.acceleration_input * car.engine_power.sample(speed_normalized)
	
	return acceleration_direction * torque

# Calculate the force necessary to align the car's velocity to the wheels
func _get_steering_force(car: Car, delta: float) -> Vector3:
	var forward_direction: Vector3 = global_basis.z
	var steering_direction: Vector3 = global_basis.x
	var state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	var local_velocity := state.get_velocity_at_local_position(global_position - car.global_position)
	
	# Save the rotational speed to spin the wheel in _process
	_current_rotational_speed = local_velocity.dot(forward_direction) / wheel_mesh_radius
	
	# Sample the current grip from the grip curve if velocity is not negligible
	var current_grip: float = 1.0
	if not is_zero_approx(local_velocity.length()):
		var alignment: float = abs(forward_direction.dot(local_velocity.normalized()))
		current_grip = grip.sample(alignment)
	
	var lateral_velocity: float = steering_direction.dot(local_velocity)
	var desired_acceleration: float = -lateral_velocity * current_grip
	
	return steering_direction * steering_strength * desired_acceleration

# Calculate friction using the normal force obtained from the suspension force
func _get_friction_force(car: Car, delta: float, suspension_force: Vector3) -> Vector3:
	var forward_direction: Vector3 = global_basis.z
	var state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	var local_velocity := state.get_velocity_at_local_position(global_position - car.global_position)
	
	var longitudinal_velocity: float = local_velocity.dot(forward_direction)
	var friction_direction: Vector3 = forward_direction * -sign(longitudinal_velocity)
	
	var normal_force: float = suspension_force.length()
	
	var friction_force: Vector3 = friction_direction * friction_coefficient * normal_force
	
	# Diminish friction at low velocity to avoid flickering
	if abs(longitudinal_velocity) < 0.1:
		friction_force *= abs(longitudinal_velocity) * 10
	
	return friction_force
