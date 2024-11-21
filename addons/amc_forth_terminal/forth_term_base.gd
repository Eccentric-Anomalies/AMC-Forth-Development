class_name ForthTermBase
## Base class and utilities for Forth terminals
##

extends RefCounted

const SCREEN_WIDTH := 80
const SCREEN_HEIGHT := 24


var forth: AMCForth
var blank_line:PackedInt32Array

# Create with a reference to AMCForth
func _init(_forth: AMCForth):
	forth = _forth
	forth.terminal_out.connect(_on_forth_output)
	# create a blank line
	blank_line = PackedInt32Array()
	blank_line.resize(SCREEN_WIDTH)
	blank_line.fill(ForthTerminal.BL.to_ascii_buffer()[0])


# The forth output handler should be overridden in child classes
func _on_forth_output(_text: String) -> void:
	pass
