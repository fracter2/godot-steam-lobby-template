@tool
class_name PhysicsPathFollower
extends PathFollow3D

# TODO, to add features allowing trains and such. Requires applying force onto them (not self, ignoring nass), correction forces (derailment when max force hit, different per direction), and possibly track properties.
#@export var atached_rigidbody: RigidBody3D						## Optional [RigidBody] node, acts as a joint in this case and ignores [member mass]
# TODO ADD AS A SEPARATE "RigidPathFollower"

# TODO motor, brake, max linear forces (before snapping), auto-resnap


func _get_configuration_warnings() -> PackedStringArray:
	return ["This is UNIMPLEMENTED. TODO"]
