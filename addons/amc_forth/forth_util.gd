class_name ForthUtil
## Forth internal utilities
##

extends RefCounted

var _forth: AMCForth


## Create with a reference to AMCForth
func _init(forth: AMCForth):
	_forth = forth


## Send a newline character to the terminal out
func emit_newline() -> void:
	_forth.terminal_out.emit(ForthTerminal.CR + ForthTerminal.LF)


## Send text to the terminal out, with a following newline
func rprint_term(text: String) -> void:
	print_term(text)
	emit_newline()


## Send text to the terminal out
func print_term(text: String) -> void:
	_forth.terminal_out.emit(text)


## Report an unrecognized Forth word
func print_unknown_word(word: String) -> void:
	rprint_term(" " + word + " ?")


## Return a gdscript String from address and length
func str_from_addr_n(addr: int, n: int) -> String:
	var t: String = ""
	for c in n:
		t = t + char(_forth.ram.get_byte(addr + c))
	return t


## Create a Forth counted string frm a gdscript string
func cstring_from_str(addr: int, s: String) -> void:
	var n: int = addr
	_forth.ram.set_byte(n, s.length())
	n += 1
	for c in s.to_ascii_buffer():
		_forth.ram.set_byte(n, c)
		n += 1


## Copy at most n String characters to address
func string_from_str(addr: int, n: int, s: String) -> void:
	var ptr: int = addr
	for c in s.substr(0, n).to_ascii_buffer():
		_forth.ram.set_byte(ptr, c)
		ptr += 1
