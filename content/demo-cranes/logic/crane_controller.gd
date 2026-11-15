extends Node

@export_custom(PROPERTY_HINT_INPUT_NAME, "loose_mode") var input_positive: StringName = &""
@export_custom(PROPERTY_HINT_INPUT_NAME, "loose_mode") var input_negative: StringName = &""

@export var auto_brake: bool = false

@export var trolley: KinematicPathFollower


func _physics_process(_delta: float) -> void:
	var input: float = Input.get_axis(input_negative, input_positive)
	trolley.input_forward = input
	if auto_brake and input == 0:
		trolley.enable_target_velocity = true
		trolley.target_velocity = 0
	else:
		trolley.enable_target_velocity = false
