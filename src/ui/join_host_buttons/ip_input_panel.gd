extends PanelContainer


@onready var port_label: Label = %PortLabel
@onready var port_input: LineEdit = %PortInput
@onready var ip_label: Label = %IPLabel
@onready var ip_input: LineEdit = %IPInput


func _ready() -> void:
	# TODO Connect all inputs to their input validifier
	# TODO Make an icon appear when port / ip is invalid
	pass


# TODO Add API Getters for if it is valid, and to get the port / ip
# TODO Emit signals when valid-status changes (enable / disable buttons)
