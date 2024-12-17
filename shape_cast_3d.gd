extends ShapeCast3D


@export var wheel_radius: float = 0.15

@onready var spring_resting_length: float = target_position.length() + wheel_radius

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	if not is_colliding():
		return
	var collision_point: Vector3 = get_collision_point(0)
	var spring_length: float = get_closest_collision_unsafe_fraction() * spring_resting_length
	DebugDraw3D.draw_line(global_position, global_position + get_closest_collision_unsafe_fraction() * target_position, Color(0, 0, 1))
	#DebugDraw3D.draw_line(global_position, global_position + target_position, Color(0, 1, 0))
	DebugDraw3D.draw_line(global_position, collision_point)
