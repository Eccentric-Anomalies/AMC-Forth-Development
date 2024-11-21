class_name ForthTermLocal
## Local Forth terminal
##

extends ForthTermBase

var _screen_ram:PackedInt32Array

## Initialize (executed automatically by ForthTermLocal.new())
##
func _init(_forth: AMCForth, screen_material:ShaderMaterial) -> void:
	super(_forth)
	# shader setup
	_screen_ram = PackedInt32Array()
	_screen_ram.resize(SCREEN_WIDTH * SCREEN_HEIGHT)
	screen_material.set_shader_parameter("ram", _screen_ram)

	# Test code FIXME
	var hello:String = "Hello, world! ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
	hello = hello + hello + hello + hello + hello + hello
	var hello_bytes:= hello.to_ascii_buffer()
	for i in hello_bytes.size():
		_screen_ram[i] = hello_bytes[i]

