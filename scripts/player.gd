extends VehicleBody3D
@export var max_steer: float = 0.9
@export var engine_power: float = 300.5
@export var acceleration: float = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("a")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print ("b")

func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("right", "left") * (max_steer), delta * acceleration)
	engine_force = (Input.get_axis("down", "up") * engine_power)
