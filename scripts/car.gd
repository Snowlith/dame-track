extends RigidBody3D
class_name Car

@export var engine_power: float = 200
@export var steering_angle: float = 20
@onready var wheels: Array[Wheel] = [%FrontLeftWheel, %FrontRightWheel, %BackLeftWheel, %BackRightWheel]

var acceleration_input: float
var steering_input: float

func _ready() -> void:
	for wheel: Wheel in wheels:
		wheel.add_exception(self)

func _physics_process(delta: float) -> void:
	acceleration_input = Input.get_axis("down", "up")
	steering_input = Input.get_axis("right", "left")
	
	%FrontLeftWheel.rotation.y = steering_input * deg_to_rad(steering_angle)
	%FrontRightWheel.rotation.y = steering_input * deg_to_rad(steering_angle)
	for wheel: Wheel in wheels:
		wheel.apply_forces(self, delta)
