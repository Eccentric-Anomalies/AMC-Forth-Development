class_name AMCForth

extends RefCounted

signal terminal_out(text: String)

const BANNER:= "AMC Forth"

func terminal_in(text: String) -> void:
	# just echo for now
	terminal_out.emit(text)

func init() -> void:
	print(BANNER)
	terminal_out.emit(BANNER + "\r\n")
