extends Node

@export_group("Trolley", "trolley_")
@export_custom(PROPERTY_HINT_INPUT_NAME, "loose_mode") var trolley_input_positive: StringName = &""
@export_custom(PROPERTY_HINT_INPUT_NAME, "loose_mode") var trolley_input_negative: StringName = &""
@export var trolley_auto_brake: bool = false
@export var trolley_node: KinematicPathFollower


func _ready() -> void:
	assert(trolley_node != null)


func _physics_process(_delta: float) -> void:
	_trolley_process()


func _trolley_process() -> void:
	var input: float = Input.get_axis(trolley_input_negative, trolley_input_positive)
	trolley_node.input_forward = input
	if trolley_auto_brake and input == 0:
		trolley_node.enable_target_velocity = true
		trolley_node.target_velocity = 0
	else:
		trolley_node.enable_target_velocity = false
