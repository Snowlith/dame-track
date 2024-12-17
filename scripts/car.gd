extends RigidBody3D
class_name Car

@export var engine_power: Curve
@export var top_speed: float = 20
@export var steering_angle: float = 20
@onready var wheels: Array[Wheel] = [%FrontLeftWheel, %FrontRightWheel, %BackLeftWheel, %BackRightWheel]

var acceleration_input: float
var steering_input: float

func _ready() -> void:
	for wheel: Wheel in wheels:
		wheel.add_collision_exception(self)

func _physics_process(delta: float) -> void:
	acceleration_input = Input.get_axis("down", "up")
	steering_input = Input.get_axis("right", "left")
	
	%FrontLeftWheel.rotation.y = steering_input * deg_to_rad(steering_angle)
	%FrontRightWheel.rotation.y = steering_input * deg_to_rad(steering_angle)
	for wheel: Wheel in wheels:
		wheel.apply_forces(self, delta)
	
	if Input.is_action_just_pressed("jump"):
		apply_central_impulse(Vector3.UP * 500)
	
	%VelocityLabel.text = str(round(Vector2(linear_velocity.x, linear_velocity.z).length()))
