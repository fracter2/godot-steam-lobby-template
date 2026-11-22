class_name MotorAttribute
extends PhysicsAttribute

@export var orce: float = 1								## Muliplied by [member motor_at_speed_curve]
@export var force_at_speed_curve: Curve 				## Muliplied by [member motor_force]. To for example: set a hard speed limit, shape how "heavy" it feels, etc
#@export var motor_forward_only: bool = false			## Only allows applying force in the forward direction.
