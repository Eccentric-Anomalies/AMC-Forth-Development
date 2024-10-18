class_name AMCForth

extends RefCounted

signal terminal_out(text: String)

const BANNER:= "AMC Forth"
const DICT_SIZE:= 0x10000
const DICT_TOP:= 0x0ffff

const TERM_BSP:= char(0x08)
const TERM_CR:= char(0x0D)
const TERM_LF:= char(0x0A)
const TERM_ESC:= char(0x1B)
const TERM_UP:= TERM_ESC + "[A"
const TERM_DOWN:= TERM_ESC + "[B"
const TERM_RIGHT:= TERM_ESC + "[C"
const TERM_LEFT:= TERM_ESC + "[D"

var _built_in_names = [
	['.', _period],
	['+', _add],
]

# get built-in "address" from word
var _built_in_address: Dictionary = {}
# get built-in function from word
var _built_in_function: Dictionary = {}
# get built-in function from "address"
var _built_in_function_from_address: Array = []

# The Forth dictionary space
var _dict:= PackedByteArray()

# terminal scratchpad and buffer
var _terminal_pad: String = ""
var _pad_position:= 0
var _terminal_buffer: Array = [""]
var _buffer_index:= 0

# handle editing input strings in interactive mode
func terminal_in(text: String) -> void:
	var in_str: String = text
	var echo_text: String = ""
	while(in_str.length() > 0):
		if in_str.left(1) == TERM_BSP:
			_pad_position = max(0, _pad_position - 1)
			if _terminal_pad.length():
				_terminal_pad[_pad_position] = " "
			echo_text = TERM_LEFT
			in_str = in_str.erase(0,1)
		elif in_str.left(3) == TERM_LEFT:
			_pad_position = max(0, _pad_position - 1)
			echo_text = TERM_LEFT
			in_str = in_str.erase(0,3)
		elif in_str.left(3) == TERM_UP:
			_buffer_index = max(0, _buffer_index - 1)
			echo_text = _select_buffered_command()
			in_str = in_str.erase(0,3)
		elif in_str.left(3) == TERM_DOWN:
			_buffer_index = min(_terminal_buffer.size()-1, _buffer_index + 1)
			echo_text = _select_buffered_command()
			in_str = in_str.erase(0,3)
		elif in_str.left(1) == TERM_LF:
			echo_text = ""
			in_str = in_str.erase(0,1)
		elif in_str.left(1) == TERM_CR:
			print("Entered: ", _terminal_pad)  # FIXME this goes to the interpreter!
			_terminal_buffer.append(_terminal_pad)
			_buffer_index = _terminal_buffer.size()
			echo_text = " "
			_terminal_pad = ""
			_pad_position = 0
			in_str = in_str.erase(0,1)
		# not a control character(s)
		else:
			echo_text = in_str.left(1)
			in_str = in_str.erase(0,1)
			for c in echo_text:
				if _pad_position < _terminal_pad.length():
					_terminal_pad[_pad_position] = c
				else:
					_terminal_pad += c
				_pad_position += 1
		terminal_out.emit(echo_text)

func init() -> void:
	print(BANNER)
	terminal_out.emit(BANNER + "\r\n")
	_init_built_ins()
	_dict.resize(DICT_SIZE)

# privates

func _select_buffered_command() -> String:
	var new_index = _buffer_index
	_buffer_index = _terminal_buffer.size()
	_terminal_pad = _terminal_buffer[new_index]
	_pad_position = _terminal_pad.length()
	print("Selecting: ", _terminal_buffer[new_index])
	return TERM_CR + _terminal_buffer[new_index]

func _init_built_ins() -> void:
	for i in _built_in_names.size():
		var word: String = _built_in_names[i][0]
		var f: Callable = _built_in_names[i][1]
		_built_in_address[word] = i
		_built_in_function[word] = f
		_built_in_function_from_address.append(f)

# built-ins
func _period() -> void:
	pass

func _add() -> void:
	pass