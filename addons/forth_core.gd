class_name ForthCore

extends RefCounted

var _forth: AMCForth


# Create with a reference to AMCForth
func _init(forth: AMCForth):
	_forth = forth


# Comments
func _start_parenthesis() -> void:
	_forth.push_word(")".to_ascii_buffer()[0])
	_forth.parse()


func left_parenthesis() -> void:
	# Begin parsing a comment, terminated by ')' character
	# ( - )
	_start_parenthesis()
	_forth.two_drop()


func dot_left_parenthesis() -> void:
	# Begin parsing a comment, terminated by ')'. Comment text
	# will emit to the terminal.
	# ( - )
	_start_parenthesis()
	_forth.type()

