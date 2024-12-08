## Terminal 2D AMC Forth Demo
extends Node2D

# Test signals FIXME
signal port_99(value: int)
signal input_100(value: int)

var _telnet_terminal: ForthTermTelnet
var _local_terminal: ForthTermLocal
var _forth: AMCForth


func _ready() -> void:
	_forth = AMCForth.new(self)
	_telnet_terminal = ForthTermTelnet.new(_forth)
	_local_terminal = ForthTermLocal.new(_forth, $Bezel/Screen.material)

	_forth.add_output_signal(99, port_99)  # FIXME test purposes
	port_99.connect(_on_port_99_output)  # FIXME output test
	input_100.connect(_forth.GetInputReceiver(100))  # FIXME input test


func _process(_delta: float) -> void:
	# perform periodic telnet processing
	_telnet_terminal.poll_connection()
	_local_terminal.update_time()


func _unhandled_key_input(evt: InputEvent) -> void:
	_local_terminal.handle_key_event(evt)
	get_viewport().set_input_as_handled()


# output test FIXME
func _on_port_99_output(value: int):
	print(value)


# test code FIXME
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_0:
			input_100.emit(666)
