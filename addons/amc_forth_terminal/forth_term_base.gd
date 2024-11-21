class_name ForthTermBase
## Base class and utilities for Forth terminals
##

extends RefCounted

const SCREEN_WIDTH := 80
const SCREEN_HEIGHT := 24

var forth: AMCForth

var output_buffer := ""

# Create with a reference to AMCForth
func _init(_forth: AMCForth):
	forth = _forth
	forth.terminal_out.connect(_on_forth_output)


func _on_forth_output(text: String) -> void:
	output_buffer += text

