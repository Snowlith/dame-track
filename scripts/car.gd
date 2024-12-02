extends RigidBody3D
class_name Car

@export var engine_power: float = 200
@onready var wheels: Array[Wheel] = [%FrontLeftWheel, %FrontRightWheel, %BackLeftWheel, %BackRightWheel]

var input: Vector2

func _ready() -> void:
	for wheel: Wheel in wheels:
		wheel.add_collision_exception(self)

func _physics_process(delta: float) -> void:
	print(" ")
	input = Input.get_vector("left", "right", "down", "up")
	for wheel: Wheel in wheels:
		wheel.apply_forces(self, delta)
	
func get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
