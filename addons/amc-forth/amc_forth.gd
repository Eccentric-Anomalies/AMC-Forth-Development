class_name AMCForth

extends RefCounted

signal terminal_out(text: String)

const BANNER := "AMC Forth"

# Memory Map
const RAM_SIZE := 0x10000  # BYTES
# Dictionary
const DICT_START := 0x0100  # BYTES
const DICT_SIZE := 0x08000
const DICT_TOP := DICT_START + DICT_SIZE
# Data Stack
const DS_START := DICT_TOP  # start of the data stack
const DS_WORDS_SIZE := 0x0200
const DS_WORDS_GUARD := 0x010  # extra words allocated to avoid exceptions
# cell size should be 2 or 4
# if 2, use (encode|decode)_(s|u)16 and (encode|decode)_(s_u)32
# if 4, use (encode|decode)_(s|u)32 and (encode|decode)_(s_u)64
const DS_CELL_SIZE := 4
const DS_DCELL_SIZE := DS_CELL_SIZE * 2
const DS_TOP := DS_START + DS_WORDS_SIZE * DS_CELL_SIZE
# Control Stack
const CS_START := DS_TOP + DS_WORDS_GUARD * DS_CELL_SIZE  # start of control stack
const CS_WORDS_SIZE := 0x0200
const CS_CELL_SIZE := 4
const CS_TOP := CS_START + CS_WORDS_SIZE * CS_CELL_SIZE

const TRUE := int(-1)
const FALSE := int(0)

const TERM_BSP := char(0x08)
const TERM_CR := char(0x0D)
const TERM_LF := char(0x0A)
const TERM_ESC := char(0x1B)
const TERM_DEL_LEFT := char(0x7F)
const TERM_DEL := TERM_ESC + "[3~"
const TERM_UP := TERM_ESC + "[A"
const TERM_DOWN := TERM_ESC + "[B"
const TERM_RIGHT := TERM_ESC + "[C"
const TERM_LEFT := TERM_ESC + "[D"
const TERM_CLREOL := TERM_ESC + "[2K"
const MAX_BUFFER_SIZE := 20

var _built_in_names = [
	# Data Stack Manipulation
	["?DUP", _q_dup],
	["DEPTH", _depth],
	["DROP", _drop],
	["DUP", _dup],
	["NIP", _nip],
	["OVER", _over],
	["PICK", _pick],
	["ROT", _rot],
	["SWAP", _swap],
	["TUCK", _tuck],
	["2DROP", _two_drop],
	["2DUP", _two_dup],
	["2OVER", _two_over],
	["2ROT", _two_rot],
	["2SWAP", _two_swap],
	# Programmer Conveniences
	[".S", _dot_s],
	[".", _dot],
	["D.", _d_dot],
	# Arithmetic
	["*", _star],
	["*/", _star_slash],
	["*/MOD", _star_slash_mod],
	["+", _plus],
	["-", _minus],
	["/", _slash],
	["/MOD", _slash_mod],
	["1+", _one_plus],
	["1-", _one_minus],
	["2+", _two_plus],
	["2-", _two_minus],
	["2*", _two_star],
	["2/", _two_slash],
	["LSHIFT", _lshift],
	["MOD", _mod],
	["RSHIFT", _rshift],
	# Double Precision Arithmetic
	["D+", _d_plus],
	["D-", _d_minus],
	["D2*", _d_two_star],
	["D2/", _d_two_slash],
	# Mixed Precision Operations
	["D>S", _d_to_s],
	["M*", _m_star],
	["M*/", _m_star_slash],
	["M+", _m_plus],
	["M-", _m_minus],
	["M/", _m_slash],
	["S>D", _s_to_d],
	["SM/REM", _sm_slash_rem],
	["UM/MOD", _um_slash_mod],
	["UM*", _um_star],
	# Logical Operators
	["ABS", _abs],
	["AND", _and],
	["INVERT", _invert],
	["MAX", _max],
	["MIN", _min],
	["NEGATE", _negate],
	["OR", _or],
	["XOR", _xor],
]

# get built-in "address" from word
var _built_in_address: Dictionary = {}
# get built-in function from word
var _built_in_function: Dictionary = {}
# get built-in function from "address"
var _built_in_function_from_address: Dictionary = {}

# The Forth dictionary space
# data stack pointer is in byte units
var _ds_p := DS_TOP
var _ram := PackedByteArray()

# terminal scratchpad and buffer
var _terminal_pad: String = ""
var _pad_position := 0
var _terminal_buffer: Array = []
var _buffer_index := 0

# forth ordering scratch
var _d_scratch := PackedByteArray()


# handle editing input strings in interactive mode
func terminal_in(text: String) -> void:
	var in_str: String = text
	var echo_text: String = ""
	var buffer_size := _terminal_buffer.size()
	while in_str.length() > 0:
		if in_str.find(TERM_DEL_LEFT) == 0:
			_pad_position = max(0, _pad_position - 1)
			if _terminal_pad.length():
				# shrink if deleting from end, else replace with space
				if _pad_position == _terminal_pad.length() - 1:
					_terminal_pad = _terminal_pad.left(_pad_position)
				else:
					_terminal_pad[_pad_position] = " "
			# reconstruct the changed entry, with correct cursor position
			echo_text = _refresh_edit_text()
			in_str = in_str.erase(0, TERM_DEL_LEFT.length())
		elif in_str.find(TERM_DEL) == 0:
			# do nothing unless cursor is in text
			if _pad_position <= _terminal_pad.length():
				_terminal_pad = _terminal_pad.erase(_pad_position)
			# reconstruct the changed entry, with correct cursor position
			echo_text = _refresh_edit_text()
			in_str = in_str.erase(0, TERM_DEL.length())
		elif in_str.find(TERM_LEFT) == 0:
			_pad_position = max(0, _pad_position - 1)
			echo_text = TERM_LEFT
			in_str = in_str.erase(0, TERM_LEFT.length())
		elif in_str.find(TERM_UP) == 0 and buffer_size:
			_buffer_index = max(0, _buffer_index - 1)
			echo_text = _select_buffered_command()
			in_str = in_str.erase(0, TERM_UP.length())
		elif in_str.find(TERM_DOWN) == 0 and buffer_size:
			_buffer_index = min(_terminal_buffer.size() - 1, _buffer_index + 1)
			echo_text = _select_buffered_command()
			in_str = in_str.erase(0, TERM_DOWN.length())
		elif in_str.find(TERM_LF) == 0:
			echo_text = ""
			in_str = in_str.erase(0, TERM_LF.length())
		elif in_str.find(TERM_CR) == 0:
			# only add to the buffer if it's different from the top entry
			# and not blank!
			if (
				_terminal_pad.length()
				and (not buffer_size or (_terminal_buffer[-1] != _terminal_pad))
			):
				_terminal_buffer.append(_terminal_pad)
				# if we just grew too big...
				if buffer_size == MAX_BUFFER_SIZE:
					_terminal_buffer.pop_front()
			_buffer_index = _terminal_buffer.size()
			_interpret_terminal_line(_terminal_pad)
			_terminal_pad = ""
			_pad_position = 0
			in_str = in_str.erase(0, TERM_CR.length())
		# not a control character(s)
		else:
			echo_text = in_str.left(1)
			in_str = in_str.erase(0, 1)
			for c in echo_text:
				if _pad_position < _terminal_pad.length():
					_terminal_pad[_pad_position] = c
				else:
					_terminal_pad += c
				_pad_position += 1
		terminal_out.emit(echo_text)


func init() -> void:
	print(BANNER)
	terminal_out.emit(BANNER + TERM_CR + TERM_LF)
	_init_built_ins()
	_ram.resize(RAM_SIZE)
	_d_scratch.resize(DS_DCELL_SIZE)


# privates


func _emit_newline() -> void:
	terminal_out.emit(TERM_CR + TERM_LF)


# print, with newline
func _rprint_term(text: String) -> void:
	_print_term(text)
	_emit_newline()


# print, without newline
func _print_term(text: String) -> void:
	terminal_out.emit(text)


# convert int to forth ordering and vice versa
func _d_swap(num: int) -> int:
	_d_scratch.encode_s64(0, num)
	var t: int = _d_scratch.decode_s32(0)
	_d_scratch.encode_s32(0, _d_scratch.decode_s32(DS_CELL_SIZE))
	_d_scratch.encode_s32(DS_CELL_SIZE, t)
	return _d_scratch.decode_s64(0)


func _strip_comments(tokens: PackedStringArray) -> PackedStringArray:
	var new_tokens: PackedStringArray = []
	var in_comment := false
	for i in tokens.size():
		if not in_comment:
			if tokens[i] == "\\":
				# end of line comment. We're done here
				return new_tokens
			if tokens[i] == "(":
				in_comment = true
			else:
				new_tokens.append(tokens[i])
		else:  # in comment
			if tokens[i][-1] == ")":
				in_comment = false
	return new_tokens


func _interpret_terminal_line(in_text: String) -> void:
	var tokens: PackedStringArray = in_text.split(" ")
	while tokens.has(""):
		tokens.remove_at(tokens.find(""))
	tokens = _strip_comments(tokens)
	for t in tokens:
		var t_up := t.to_upper()
		if t_up in _built_in_function:
			_built_in_function[t_up].call()
		# valid numeric value (double first)
		elif t.contains(".") and t.replace(".", "").is_valid_int():
			var t_strip: String = t.replace(".", "")
			var temp: int = t_strip.to_int()
			_ds_p -= DS_DCELL_SIZE
			_ram.encode_s64(_ds_p, _d_swap(temp))
		elif t.is_valid_int():
			var temp: int = t.to_int()
			# limit entries to 16-bit values
			_ds_p -= DS_CELL_SIZE
			_ram.encode_s32(_ds_p, temp)
		# nothing we recognize
		else:
			_rprint_term(" " + t + " ?")
			return  # not ok
		# check the stack
		if _ds_p < DS_START + DS_WORDS_GUARD:
			_rprint_term(" Data stack overflow")
			_ds_p = DS_START + DS_WORDS_GUARD
			return  # not ok
		if _ds_p > DS_TOP:
			_rprint_term(" Data stack underflow")
			_ds_p = DS_TOP
			return  # not ok
	_rprint_term(" ok")


# return echo text that refreshes the current edit
func _refresh_edit_text() -> String:
	var echo = TERM_CLREOL + TERM_CR + _terminal_pad + TERM_CR
	for i in range(_pad_position):
		echo += TERM_RIGHT
	return echo


func _select_buffered_command() -> String:
	var selected_index = _buffer_index
	_terminal_pad = _terminal_buffer[selected_index]
	_pad_position = _terminal_pad.length()
	return TERM_CLREOL + TERM_CR + _terminal_pad


func _init_built_ins() -> void:
	for i in _built_in_names.size():
		var word: String = _built_in_names[i][0]
		var f: Callable = _built_in_names[i][1]
		_built_in_address[word] = i * 2
		_built_in_function[word] = f
		_built_in_function_from_address[i * 2] = f


# built-ins
# STACK
func _q_dup() -> void:
	# ( x - 0 | x x )
	var t: int = _ram.decode_s32(_ds_p)
	if t != 0:
		_ds_p -= DS_CELL_SIZE
		_ram.encode_s32(_ds_p, t)


func _depth() -> void:
	# ( - +n )
	var t: int = (DS_TOP - _ds_p) / DS_CELL_SIZE
	_ds_p -= DS_CELL_SIZE
	_ram.encode_u32(_ds_p, t)


func _drop() -> void:
	# ( x - )
	_ds_p += DS_CELL_SIZE


func _dup() -> void:
	# ( x - x x )
	var t: int = _ram.decode_s32(_ds_p)
	_ds_p -= DS_CELL_SIZE
	_ram.encode_s32(_ds_p, t)


func _nip() -> void:
	# drop second item, leaving top unchanged
	# ( x1 x2 - x2 )
	var t: int = _ram.decode_s32(_ds_p)
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(_ds_p, t)


func _over() -> void:
	# place a copy of x1 on top of the stack
	# ( x1 x2 - x1 x2 x1 )
	_ds_p -= DS_CELL_SIZE
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p + 2 * DS_CELL_SIZE))


func _pick() -> void:
	# place a copy of the nth stack entry on top of the stack
	# zeroth item is the top of the stack so 0 pick is dup
	# ( +n - x )
	var t: int = _ram.decode_s32(_ds_p)
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p + (t + 1) * DS_CELL_SIZE))


func _rot() -> void:
	# rotate the top three items on the stack
	# ( x1 x2 x3 - x2 x3 x1 )
	var t: int = _ram.decode_s32(_ds_p + 2 * DS_CELL_SIZE)
	_ram.encode_s32(
		_ds_p + 2 * DS_CELL_SIZE, _ram.decode_s32(_ds_p + DS_CELL_SIZE)
	)
	_ram.encode_s32(_ds_p + DS_CELL_SIZE, _ram.decode_s32(_ds_p))
	_ram.encode_s32(_ds_p, t)


func _swap() -> void:
	# exchange the top two items on the stack
	# ( x1 x2 - x2 x1 )
	var t: int = _ram.decode_s32(_ds_p + DS_CELL_SIZE)
	_ram.encode_s32(_ds_p + DS_CELL_SIZE, _ram.decode_s32(_ds_p))
	_ram.encode_s32(_ds_p, t)


func _tuck() -> void:
	# place a copy of the top stack item below the second stack item
	# ( x1 x2 - x2 x1 x2 )
	_ram.encode_s32(_ds_p - DS_CELL_SIZE, _ram.decode_s32(_ds_p))
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p + DS_CELL_SIZE))
	_ram.encode_s32(_ds_p + DS_CELL_SIZE, _ram.decode_s32(_ds_p - DS_CELL_SIZE))
	_ds_p -= DS_CELL_SIZE


func _two_drop() -> void:
	# remove the top pair of cells from the stack
	# ( x1 x2 - )
	_ds_p += DS_DCELL_SIZE


func _two_dup() -> void:
	# duplicate the top cell pair
	# (x1 x2 - x1 x2 x1 x2 )
	_ds_p -= DS_DCELL_SIZE
	_ram.encode_s64(_ds_p, _ram.decode_s64(_ds_p + DS_DCELL_SIZE))


func _two_over() -> void:
	# copy a cell pair x1 x2 to the top of the stack
	# ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
	_ds_p -= DS_DCELL_SIZE
	_ram.encode_s64(_ds_p, _ram.decode_s64(_ds_p + 2 * DS_DCELL_SIZE))


func _two_rot() -> void:
	# rotate the top three cell pairs on the stack
	# ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
	var t: int = _ram.decode_s64(_ds_p + 2 * DS_DCELL_SIZE)
	_ram.encode_s64(
		_ds_p + 2 * DS_DCELL_SIZE, _ram.decode_s64(_ds_p + DS_DCELL_SIZE)
	)
	_ram.encode_s64(_ds_p + DS_DCELL_SIZE, _ram.decode_s64(_ds_p))
	_ram.encode_s64(_ds_p, t)


func _two_swap() -> void:
	# exchange the top two cell pairs
	# ( x1 x2 x3 x4 - x3 x4 x1 x2 )
	var t: int = _ram.decode_s64(_ds_p + DS_DCELL_SIZE)
	_ram.encode_s64(_ds_p + DS_DCELL_SIZE, _ram.decode_s64(_ds_p))
	_ram.encode_s64(_ds_p, t)


# Programmer Conveniences
func _dot_s() -> void:
	var pointer = DS_TOP - DS_CELL_SIZE
	_rprint_term("")
	while pointer >= _ds_p:
		_print_term(" " + str(_ram.decode_s32(pointer)))
		pointer -= DS_CELL_SIZE
	_print_term(" <-Top")


func _dot() -> void:
	_print_term(" " + str(_ram.decode_s32(_ds_p)))
	_ds_p += DS_CELL_SIZE


func _d_dot() -> void:
	_print_term(" " + str(_d_swap(_ram.decode_s64(_ds_p))))
	_ds_p += DS_DCELL_SIZE


func _star() -> void:
	# Multiply n1 by n2 leaving the product n3
	# ( n1 n2 - n3 )
	var t: int = _ram.decode_s32(_ds_p) * _ram.decode_s32(_ds_p + DS_CELL_SIZE)
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(_ds_p, t)


func _star_slash() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell quotient n4.
	# ( n1 n2 n3 - n4 )
	var p: int = (
		_ram.decode_s32(_ds_p + DS_CELL_SIZE)
		* _ram.decode_s32(_ds_p + DS_CELL_SIZE * 2)
	)
	var q: int = p / _ram.decode_s32(_ds_p)
	_ds_p += DS_CELL_SIZE * 2
	_ram.encode_s32(_ds_p, q)


func _star_slash_mod() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell remainder n4
	# and a single-cell quotient n5
	# ( n1 n2 n3 - n4 n5 )
	var p: int = (
		_ram.decode_s32(_ds_p + DS_CELL_SIZE)
		* _ram.decode_s32(_ds_p + DS_CELL_SIZE * 2)
	)
	var r: int = p % _ram.decode_s32(_ds_p)
	var q: int = p / _ram.decode_s32(_ds_p)
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(_ds_p, q)  # quotient
	_ram.encode_s32(_ds_p + DS_CELL_SIZE, r)  # remainder


func _plus() -> void:
	# Add n1 to n2 leaving the sum n3
	# ( n1 n2 - n3 )
	var t: int = _ram.decode_s32(_ds_p) + _ram.decode_s32(_ds_p + DS_CELL_SIZE)
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(_ds_p, t)


func _minus() -> void:
	# subtract n2 from n1, leaving the diference n3
	# ( n1 n2 - n3 )
	var t: int = _ram.decode_s32(_ds_p + DS_CELL_SIZE) - _ram.decode_s32(_ds_p)
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(_ds_p, t)


func _slash() -> void:
	# divide n1 by n2, leaving the quotient n3
	# ( n1 n2 - n3 )
	var t: int = _ram.decode_s32(_ds_p + DS_CELL_SIZE) / _ram.decode_s32(_ds_p)
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(_ds_p, t)


func _slash_mod() -> void:
	# divide n1 by n2, leaving the remainder n3 and quotient n4
	# ( n1 n2 - n3 n4 )
	var q: int = _ram.decode_s32(_ds_p + DS_CELL_SIZE) / _ram.decode_s32(_ds_p)
	var r: int = _ram.decode_s32(_ds_p + DS_CELL_SIZE) % _ram.decode_s32(_ds_p)
	_ram.encode_s32(_ds_p, q)
	_ram.encode_s32(_ds_p + DS_CELL_SIZE, r)


func _one_plus() -> void:
	# Add one to n1, leaving n2
	# ( n1 - n2 )
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p) + 1)


func _one_minus() -> void:
	# Subtract one from n1, leaving n2
	# ( n1 - n2 )
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p) - 1)


func _two_plus() -> void:
	# Add two to n1, leaving n2
	# ( n1 - n2 )
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p) + 2)


func _two_minus() -> void:
	# Subtract two from n1, leaving n2
	# ( n1 - n2 )
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p) - 2)


func _two_star() -> void:
	# Return x2, result of shifting x1 one bit towards the MSB,
	# filling the LSB with zero
	# ( x1 - x2 )
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p) << 1)


func _two_slash() -> void:
	# Return x2, result of shifting x1 one bit towards LSB,
	# leaving the MSB unchanged
	# ( x1 - x2 )
	_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p) >> 1)


func _lshift() -> void:
	# Perform a logical left shift of u places on x1, giving x2._add_constant_central_force
	# Fill the vacated LSB bits with zero
	# (x1 u - x2 )
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(
		_ds_p, _ram.decode_s32(_ds_p) << _ram.decode_s32(_ds_p - DS_CELL_SIZE)
	)


func _mod() -> void:
	# Divide n1 by n2, giving the remainder n3
	# (n1 n2 - n3 )
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(
		_ds_p, _ram.decode_s32(_ds_p) % _ram.decode_s32(_ds_p - DS_CELL_SIZE)
	)


func _rshift() -> void:
	# Perform a logical right shift of u places on x1, giving x2.
	# Fill the vacated MSB bits with zeroes
	# ( x1 u - x2 )
	_ds_p += DS_CELL_SIZE
	_ram.encode_s32(
		_ds_p, _ram.decode_u32(_ds_p) >> _ram.decode_s32(_ds_p - DS_CELL_SIZE)
	)


func _d_plus() -> void:
	# Add d1 to d2, leaving the sum d3
	# ( d1 d2 - d3 )
	_ds_p += DS_DCELL_SIZE
	_ram.encode_s64(
		_ds_p,
		_d_swap(
			(
				_d_swap(_ram.decode_s64(_ds_p))
				+ _d_swap(_ram.decode_s64(_ds_p - DS_DCELL_SIZE))
			)
		)
	)


func _d_minus() -> void:
	# Subtract d2 from d1, leaving the difference d3
	# ( d1 d2 - d3 )
	_ds_p += DS_DCELL_SIZE
	_ram.encode_s64(
		_ds_p,
		_d_swap(
			(
				_d_swap(_ram.decode_s64(_ds_p))
				- _d_swap(_ram.decode_s64(_ds_p - DS_DCELL_SIZE))
			)
		)
	)


func _d_two_star() -> void:
	# Multiply d1 by 2, leaving the result d2
	# ( d1 - d2 )
	_ram.encode_s64(_ds_p, _d_swap(_d_swap(_ram.decode_s64(_ds_p)) * 2))


func _d_two_slash() -> void:
	# Divide d1 by 2, leaving the result d2
	# ( d1 - d2 )
	_ram.encode_s64(_ds_p, _d_swap(_d_swap(_ram.decode_s64(_ds_p)) / 2))


func _d_to_s() -> void:
	# Convert double to single, discarding MS cell.
	# ( d - n )
	# this assumes doubles are pushed in LS MS order
	_ds_p += DS_CELL_SIZE


func _m_star() -> void:
	# Multiply n1 by n2, leaving the double result d.
	# ( n1 n2 - d )
	_ram.encode_s64(
		_ds_p,
		_d_swap(_ram.decode_s32(_ds_p) * _ram.decode_s32(_ds_p + DS_CELL_SIZE))
	)


func _m_star_slash() -> void:
	# Multiply d1 by n1 producing a triple cell intermediate result t.
	# Divide t by n2, giving quotient d2.
	# Use this with n1 or n2 = 1 to accomplish double precision multiplication
	# or division.
	# ( d1 n1 +n2 - d2 )
	# Following is an *approximate* implementation, using the double float
	var q: float = (
		float(_ram.decode_s32(_ds_p + DS_CELL_SIZE)) / _ram.decode_s32(_ds_p)
	)
	_ds_p += DS_CELL_SIZE * 2
	_ram.encode_s64(_ds_p, _d_swap(_d_swap(_ram.decode_s64(_ds_p)) * q))


func _m_plus() -> void:
	# Add n to d1 leaving the sum d2
	# ( d1 n - d2 )
	_ds_p += DS_CELL_SIZE
	_ram.encode_s64(
		_ds_p,
		_d_swap(
			(
				_d_swap(_ram.decode_s64(_ds_p))
				+ _ram.decode_s32(_ds_p - DS_CELL_SIZE)
			)
		)
	)


func _m_minus() -> void:
	# Subtract n from d1 leaving the difference d2
	# ( d1 n - d2 )
	_ds_p += DS_CELL_SIZE
	_ram.encode_s64(
		_ds_p,
		_d_swap(
			(
				_d_swap(_ram.decode_s64(_ds_p))
				- _ram.decode_s32(_ds_p - DS_CELL_SIZE)
			)
		)
	)


func _m_slash() -> void:
	# Divide d by n1 leaving the single precision quotient n2
	# ( d n1 - n2 )
	var t: int = (
		_d_swap(_ram.decode_s64(_ds_p + DS_CELL_SIZE)) / _ram.decode_s32(_ds_p)
	)
	_ds_p += DS_DCELL_SIZE
	_ram.encode_s32(_ds_p, t)


func _s_to_d() -> void:
	# Convert a single cell number n to its double equivalent d
	# ( n - d )
	var t: int = _ram.decode_s32(_ds_p)
	_ds_p += DS_CELL_SIZE - DS_DCELL_SIZE
	_ram.encode_s64(_ds_p, _d_swap(t))


func _sm_slash_rem() -> void:
	# Divide d by n1, using symmetric division, giving quotient n3 and
	# remainder n2. All arguments are signed.
	# ( d n1 - n2 n3 )
	var dd: int = _d_swap(_ram.decode_s64(_ds_p + DS_CELL_SIZE))
	var d: int = _ram.decode_s32(_ds_p)
	var q: int = dd / d
	var r: int = dd % d
	_ds_p += DS_DCELL_SIZE - DS_CELL_SIZE
	_ram.encode_s32(_ds_p, q)
	_ram.encode_s32(_ds_p + DS_CELL_SIZE, r)


func _um_slash_mod() -> void:
	# Divide ud by n1, leaving quotient n3 and remainder n2.
	# All arguments and result are unsigned.
	# ( d u1 - u2 u3 )
	var dd: int = _d_swap(_ram.decode_u64(_ds_p + DS_CELL_SIZE))
	var d: int = _ram.decode_u32(_ds_p)
	var q: int = dd / d
	var r: int = dd % d
	_ds_p += DS_DCELL_SIZE - DS_CELL_SIZE
	_ram.encode_u32(_ds_p, q)
	_ram.encode_u32(_ds_p + DS_CELL_SIZE, r)


func _um_star() -> void:
	# Multiply u1 by u2, leaving the double-precision result ud
	# ( u1 u2 - ud )
	_ram.encode_u64(
		_ds_p,
		_d_swap(_ram.decode_u32(_ds_p + DS_CELL_SIZE) * _ram.decode_u32(_ds_p))
	)

# Logical Operators
func _abs() -> void:
	# Replace the top stack item with its absolute value
	# ( n - +n )
	_ram.encode_u32(_ds_p, abs(_ram.decode_s32(_ds_p)))

func _and() -> void:
	# Return x3, the bit-wise logical and of x1 and x2
	# ( x1 x2 - x3)
	_ds_p += DS_CELL_SIZE
	_ram.encode_u32(_ds_p, _ram.decode_u32(_ds_p) & _ram.decode_u32(_ds_p - DS_CELL_SIZE))

func _invert() -> void:
	# Invert all bits of x1, giving its logical inverse x2
	# ( x1 - x2 )
	_ram.encode_u32(_ds_p, ~ _ram.decode_u32(_ds_p))

func _max() -> void:
	# Return n3, the greater of n1 and n2
	# ( n1 n2 - n3 )
	_ds_p += DS_CELL_SIZE
	var lt:bool = _ram.decode_s32(_ds_p) < _ram.decode_s32(_ds_p - DS_CELL_SIZE)
	if lt:
		_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p - DS_CELL_SIZE))

func _min() -> void:
	# Return n3, the lesser of n1 and n2
	# ( n1 n2 - n3 )
	_ds_p += DS_CELL_SIZE
	var gt:bool = _ram.decode_s32(_ds_p) > _ram.decode_s32(_ds_p - DS_CELL_SIZE)
	if gt:
		_ram.encode_s32(_ds_p, _ram.decode_s32(_ds_p - DS_CELL_SIZE))

func _negate() -> void:
	# Change the sign of the top stack value
	# ( n - -n )
	_ram.encode_s32(_ds_p, - _ram.decode_s32(_ds_p))

func _or() -> void:
	# Return x3, the bit-wise inclusive or of x1 with x2
	# ( x1 x2 - x3 )
	_ds_p += DS_CELL_SIZE
	_ram.encode_u32(_ds_p, _ram.decode_u32(_ds_p) | _ram.decode_u32(_ds_p - DS_CELL_SIZE))

func _xor() -> void:
	# Return x3, the bit-wise exclusive or of x1 with x2
	# ( x1 x2 - x3 )
	_ds_p += DS_CELL_SIZE
	_ram.encode_u32(_ds_p, _ram.decode_u32(_ds_p) ^ _ram.decode_u32(_ds_p - DS_CELL_SIZE))
