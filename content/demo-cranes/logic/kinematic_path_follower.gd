class_name KinematicPathFollower
extends PathFollow3D

# TODO MOVE TO RESOURCE
# TODO CONSIDER MERGING FORCES AND THEIR CURVES

@export_range(0.001, 100, 0.5, "or_greater", "exp") var mass: float = 1
@export var gravity_multiplier: float = 0 						## How much the environments gravity is applied to accel and deaccel
@export var endpoints_colision_bounce: float = 0				## Multiplies [member velocity] by this amount when coliding with the start or end points of the track. Non-zero for bounce.

@export_group("Motor", "motor")									## Allows applying force according to [member input_forward] and [member target_velocity].
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var motor_enabled: bool = false
@export var motor_force: float = 1								## Muliplied by [member motor_at_speed_curve]
@export var motor_force_at_speed_curve: Curve 					## Muliplied by [member motor_force]. To for example: set a hard speed limit, shape how "heavy" it feels, etc
#@export var motor_forward_only: bool = false					## Only allows applying force in the forward direction.

@export_group("Brakes", "brake")								## Allows applying force to deaccelerate according to
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var brake_enabled: bool = false
#@export var brake_with_motor_help: bool = true					## Applies motor to assist braking
@export var brake_force: float = 10								##
@export var brake_force_at_speed_curve: Curve 					##

@export_group("Drag")
@export var drag_multiplier: float = 0.02						## Velocity fraction lost to drag every second
@export var drag_constant: float = 0.001						## Velocity lost
@export var stationary_speed_threshold: float = 0.05			## Minimum speed to be considered stationary, applying [stationary_drag_const] to simulate standing friction
@export var stationary_drag_const: float = 0.1					## Flat drag applied to speed when below [member stationary_speed_threshold]. Overrides [member drag_constant] when applied.

signal pre_physics()
signal post_physics()
signal path_end_reached()
signal path_start_reached()

var input_forward: float = 0									## -1 to 1 input value.
var enable_target_velocity: bool = false						## Set to enable [member target_velocity].
var target_velocity: float = 0									## Any speed, to which it will acceleate (if able). Negative for reverse. Ignored when [member enable_target_velocity] is false or [member input_forward] is opposite.

var velocity: float = 0

# TODO decide controller model...
# Export a PAWN or INPUT or similar resource, with list of action-name + callable + range-of-values


func _physics_process(delta: float) -> void:
	pre_physics.emit()
	_velocity_update(delta)
	_position_update(delta)
	post_physics.emit()


func _velocity_update(delta: float) -> void:
	var new_vel: float = velocity + _get_drag_delta(velocity) * delta

	# TODO In a propper system these steps would run independent, so braking runs fully before motor...
	# Both to have correct logic (so brakes influences motor...) and to allow measuring usage of different elements separately
	var accel_cap: float = _force_to_vel(_get_motor_force(new_vel)) * delta
	var deaccel_cap: float = _force_to_vel(_get_motor_force(new_vel) + _get_brake_force(new_vel)) * delta

	if enable_target_velocity:
		new_vel = _move_towards_target_velocity(new_vel, target_velocity, accel_cap, deaccel_cap)

	else:
		var is_braking: bool = (input_forward > 0) != (velocity > 0)
		new_vel += (deaccel_cap if is_braking else accel_cap) * input_forward

	velocity = new_vel


func _position_update(_delta: float) -> void:
	var prev_progress: float = progress_ratio
	progress += velocity
	if progress_ratio != prev_progress:
		if progress_ratio == 1:
			path_end_reached.emit()
			velocity *= -endpoints_colision_bounce
		if progress_ratio == 0:
			path_start_reached.emit()
			velocity *= -endpoints_colision_bounce


##
## ---- Helper Funcs ----
##

func is_stationary() -> bool:
	return velocity < stationary_speed_threshold


func _force_to_vel(force: float) -> float:
	return (1 / mass) * force	# Inverse mass


## Accelerated up to target_vel. Works for both positive or negative directions.
## If force direction is opposite target, target will be ignored.
## So if vel is already higher than
func _move_towards_target_velocity(vel: float, target_vel: float, accel_cap: float, deaccel_cap: float) -> float:
	if vel == target_vel:
		return vel

	var is_negative: bool = vel < 0
	var polarity: float = (-1 if is_negative else 1) # To allow accel / deaccel in the opposite direction

	var target_delta: float = (target_vel - vel) * polarity
	var final_delta:float = clampf(target_delta, -deaccel_cap, accel_cap) * polarity

	return vel + final_delta




# TODO LATER MOVE TO CONFIG RESOURCE
# Possibly in smaller delegated steps... pure funcs + combined object-funcs?

# TODO LATER MAKE EACH STEP (motor, brakes, drag) INTO SUB-RESOURCES THAT JUST
# STORE CONFIG + THEIR OWN PURE FUNCS!
# Enabling + disabling is a wrapper sub-resource
# Input is a resource-specific var... OR A WRAPPER-RESOURCE

# Readonly, mass-independent
func _get_drag_delta(vel: float) -> float:
	# Flip negativity to later unflip, allowing identical logic for pos/neg values
	#var is_negative: bool = vel < 0
	var speed: float = absf(vel)

	var flat_drag: float = drag_constant + (stationary_drag_const if is_stationary() else 0.0)
	speed = clampf(speed - flat_drag, 0, speed)

	var dynamic_drag: float = speed * drag_multiplier
	speed = clampf(speed - dynamic_drag, 0, speed)

	var vel_delta: float = (speed - vel) #* (-1.0 if is_negative else 1.0)
	return vel_delta


# Readonly, positive only
func _get_motor_force(vel: float) -> float:
	if not motor_enabled:
		return 0
	# TODO LATER delegate to input wrapper resource

	var absolute_vel: float = absf(vel)

	var force: float = motor_force
	if motor_force_at_speed_curve:
		force *= motor_force_at_speed_curve.sample(absolute_vel)

	return force


# Readonly, positive only
func _get_brake_force(vel: float) -> float:
	if not brake_enabled:
		return 0

	var absolute_vel: float = absf(vel)
	var force: float = brake_force
	if brake_force_at_speed_curve:
		force *= brake_force_at_speed_curve.sample(absolute_vel)

	return force
