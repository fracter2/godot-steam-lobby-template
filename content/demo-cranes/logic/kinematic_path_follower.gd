class_name KinematicPathFollower
extends PathFollow3D

# TODO MOVE TO RESOURCE
# TODO CONSIDER MERGING FORCES AND THEIR CURVES

@export_range(0, 100, 0.5, "or_greater", "exp") var mass: float = 1
@export var gravity_multiplier: float = 0 						## How much the environments gravity is applied to accel and deaccel

@export_group("Motor", "motor")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var motor_enabled: bool = false
@export var motor_force: float = 1								## Muliplied by [member motor_at_speed_curve]
@export var motor_force_at_speed_curve: Curve 					## Muliplied by [member motor_force]. To for example: set a hard speed limit, shape how "heavy" it feels, etc
@export var motor_forward_only: bool = false					## Only applies force to one direction

@export_group("Brakes", "brake")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var brake_enabled: bool = false
@export var brake_with_motor_help: bool = true					## Applies motor to assist braking
@export var brake_force: float = 10								##
@export var brake_force_at_speed_curve: Curve 					##

@export_group("Drag")
@export var drag_multiplier: float = 0.02						## Velocity fraction lost to drag every second
@export var drag_constant: float = 0.001						## Velocity lost
@export var stationary_speed_threshold: float = 0.2				## Minimum speed to be considered stationary, applying [stationary_drag_const] to simulate standing friction
@export var stationary_drag_const: float = 0.1					## Flat drag applied to speed when below [member stationary_speed_threshold]. Overrides [member drag_constant] when applied.


# TODO decide controller model...
# Export a PAWN or INPUT or similar resource, with list of action-name + callable + range-of-values

# TODO helper functions to...
# move_to_target_speed(target_speed)

# TODO NO CALLABLE FOR SMART-VALUES, instead SIGNAL when PROCESSING, property-rsource can be modified instead
