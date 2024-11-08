class_name ForthUtil

extends RefCounted

var _forth: AMCForth


# Create with a reference to AMCForth
func _init(forth: AMCForth):
	_forth = forth


func emit_newline() -> void:
	_forth.terminal_out.emit(ForthTerminal.CR + ForthTerminal.LF)


# print, with newline
func rprint_term(text: String) -> void:
	print_term(text)
	emit_newline()


# print, without newline
func print_term(text: String) -> void:
	_forth.terminal_out.emit(text)


# report an unknown word
func print_unknown_word(word: String) -> void:
	rprint_term(" " + word + " ?")


# gdscript String from address and length
func str_from_addr_n(addr: int, n: int) -> String:
	var t: String = ""
	for c in n:
		t = t + char(_forth.ram.get_byte(addr + c))
	return t


# counted string from gdscript String
func cstring_from_str(addr: int, s: String) -> void:
	var n: int = addr
	_forth.ram.set_byte(n, s.length())
	n += 1
	for c in s.to_ascii_buffer():
		_forth.ram.set_byte(n, c)
		n += 1