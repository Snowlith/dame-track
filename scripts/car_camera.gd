extends Camera3D

@export var car: Car
@export var offset := Vector3(0, 1, -2)
@export var velocity_threshold: float = 1
@export var smooth_factor: float = 3.0  

var _current_camera_direction := Vector3.FORWARD

func _physics_process(delta):
	if not car:
		return
	
	var target_direction: Vector3
	
	if car.linear_velocity.length() > velocity_threshold:
		target_direction = car.linear_velocity.normalized()
	else:
		target_direction = car.global_transform.basis.z.normalized()

	_current_camera_direction = _current_camera_direction.slerp(target_direction, delta * smooth_factor)

	global_position = car.global_position + _current_camera_direction * offset.z + Vector3(0, offset.y, 0)
	look_at(car.global_position, Vector3.UP)
