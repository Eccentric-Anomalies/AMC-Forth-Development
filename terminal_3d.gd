## Terminal 3D AMC Forth Demo
extends Node3D

var _telnet_terminal: ForthTermTelnet
var _local_terminal: ForthTermLocal


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var forth = AMCForth.new()
	forth.Initialize(self)
	_telnet_terminal = ForthTermTelnet.new(forth)
	_local_terminal = ForthTermLocal.new(forth, $Bezel/Screen.mesh.material)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# perform periodic telnet processing
	_telnet_terminal.poll_connection()
	_local_terminal.update_time()


func _unhandled_key_input(evt: InputEvent) -> void:
	_local_terminal.handle_key_event(evt)
	get_viewport().set_input_as_handled()
