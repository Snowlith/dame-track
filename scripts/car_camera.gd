extends Camera3D

@export var car: Car
@export var offset := Vector3(0, 2, -4)
@export var velocity_threshold: float = 0.5
@export var smooth_factor: float = 0.1  

var _latest_car_position: Vector3
var _latest_car_velocity: Vector3
var _current_camera_direction: Vector3 = Vector3.FORWARD

func _ready():
	process_physics_priority = 100 # Ensure update after car

func _physics_process(delta):
	_latest_car_position = car.global_position
	_latest_car_velocity = car.linear_velocity
	
	var velocity_length = _latest_car_velocity.length()
	
	var target_direction: Vector3
	if velocity_length > velocity_threshold:
		target_direction = _latest_car_velocity.normalized()
	else:
		target_direction = car.global_transform.basis.z.normalized()

	# Smoothly interpolate the current camera direction
	_current_camera_direction = _current_camera_direction.slerp(target_direction, smooth_factor)
	
	DebugDraw3D.draw_line(_latest_car_position, _latest_car_position - _current_camera_direction)
	DebugDraw3D.draw_line(_latest_car_position, _latest_car_position - target_direction)

	# Update camera position and orientation
	var target_position = _latest_car_position + _current_camera_direction * offset.z + Vector3(0, offset.y, 0)
	global_position = target_position
	look_at(_latest_car_position, Vector3.UP)
