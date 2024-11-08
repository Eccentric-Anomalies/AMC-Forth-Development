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
const DS_WORDS_SIZE := 0x040
const DS_WORDS_GUARD := 0x010  # extra words allocated to avoid exceptions
const DS_TOP := DS_START + DS_WORDS_SIZE * ForthRAM.CELL_SIZE
# Control Stack
const CS_START := DS_TOP + DS_WORDS_GUARD * ForthRAM.CELL_SIZE  # start of control stack
const CS_WORDS_SIZE := 0x020
const CS_CELL_SIZE := 4
const CS_TOP := CS_START + CS_WORDS_SIZE * CS_CELL_SIZE
# Input Buffer
const BUFF_SOURCE_SIZE := 0x0100  # bytes
const BUFF_SOURCE_START := CS_TOP
const BUFF_SOURCE_TOP := BUFF_SOURCE_START + BUFF_SOURCE_SIZE
# Pointer to the parse position in the buffer
const BUFF_TO_IN := BUFF_SOURCE_TOP
const BUFF_TO_IN_TOP := BUFF_TO_IN + ForthRAM.CELL_SIZE
# Temporary word storage (used by WORD)
const WORD_SIZE := 0x0100
const WORD_START := BUFF_TO_IN_TOP
const WORD_TOP := WORD_START + WORD_SIZE

# VIRTUAL addresses for built-in words
const DICT_VIRTUAL_START := 0x01000000
# VIRTUAL addresses for built-in execute-time functions
const DICT_VIRTUAL_EXEC_START := 0x02000000

const TRUE := int(-1)
const FALSE := int(0)

const MAX_BUFFER_SIZE := 20

# Reference to the physical memory and utilities
var ram: ForthRAM
var util: ForthUtil

# Built-In names have a run-time definition
var _built_in_names = [
	["(", _left_parenthesis],
	[".(", _dot_left_parenthesis],
	["\\", _back_slash],
	["+", _plus],
	["-", _minus],
	[",", _comma],
	[".", _dot],
	["1+", _one_plus],
	["1-", _one_minus],
	["2+", _two_plus],
	["2-", _two_minus],
	["'", _tick],
	["!", _store],
	["*", _star],
	["*/", _star_slash],
	["*/MOD", _star_slash_mod],
	[".S", _dot_s],
	["/", _slash],
	["/MOD", _slash_mod],
	["?", _question],
	["?DUP", _q_dup],
	["@", _fetch],
	[">IN", _to_in],
	["2*", _two_star],
	["2/", _two_slash],
	["2CONSTANT", _two_constant],
	["2DROP", _two_drop],
	["2DUP", _two_dup],
	["2OVER", _two_over],
	["2ROT", _two_rot],
	["2SWAP", _two_swap],
	["2VARIABLE", _two_variable],
	["ABS", _abs],
	["ALLOT", _allot],
	["AND", _and],
	["BL", _b_l],
	["BUFFER:", _buffer_colon],
	["C,", _c_comma],
	["CELL+", _cell_plus],
	["CELLS", _cells],
	["CHAR+", _char_plus],
	["CHARS", _chars],
	["CMOVE", _c_move],
	["CMOVE>", _c_move_up],
	["COMPARE", _compare],
	["CONSTANT", _constant],
	["COUNT", _count],
	["CREATE", _create],
	["D.", _d_dot],
	["D-", _d_minus],
	["D+", _d_plus],
	["D>S", _d_to_s],
	["D2*", _d_two_star],
	["D2/", _d_two_slash],
	["DABS", _d_abs],
	["DEPTH", _depth],
	["DMAX", _d_max],
	["DMIN", _d_min],
	["DNEGATE", _d_negate],
	["DROP", _drop],
	["DUP", _dup],
	["EMIT", _emit],
	["EXECUTE", _execute],
	["HERE", _here],
	["INVERT", _invert],
	["LSHIFT", _lshift],
	["M-", _m_minus],
	["M*", _m_star],
	["M*/", _m_star_slash],
	["M/", _m_slash],
	["M+", _m_plus],
	["MAX", _max],
	["MIN", _min],
	["MOD", _mod],
	["MOVE", _move],
	["NEGATE", _negate],
	["NIP", _nip],
	["OR", _or],
	["OVER", _over],
	["PARSE", _parse],
	["PICK", _pick],
	["ROT", _rot],
	["RSHIFT", _rshift],
	["S>D", _s_to_d],
	["SM/REM", _sm_slash_rem],
	["SOURCE", _source],
	["SWAP", _swap],
	["TO", _to],
	["TUCK", _tuck],
	["TYPE", _type],
	["UM*", _um_star],
	["UM/MOD", _um_slash_mod],
	["UNUSED", _unused],
	["VALUE", _value],
	["VARIABLE", _variable],
	["WORD", _word],
	["WORDS", _words],
	["XOR", _xor],
]

# list of built-in functions that have different
# compiled (execution token) behavior. Only ADD new functions
# to the end of the list, without changing order.
var _built_in_exec_functions = [
	_create_exec,
	_constant_exec,
	_two_constant_exec,
	_value_exec,
]

# get built-in "address" from word
var _built_in_address: Dictionary = {}
# get built-in function from word
var _built_in_function: Dictionary = {}
# get built-in function from "address"
var _built_in_function_from_address: Dictionary = {}
# get address from built-in function
var _address_from_built_in_function: Dictionary = {}

# The Forth dictionary space
var _dict_p := DICT_START  # position of last link
var _dict_top := DICT_START  # position of next new link to create
var _dict_ip := 0  # code field pointer set to current execution point

# The Forth data stack pointer is in byte units
var _ds_p := DS_TOP

# terminal scratchpad and buffer
var _terminal_pad: String = ""
var _pad_position := 0
var _parse_pointer := 0
var _terminal_buffer: Array = []
var _buffer_index := 0


# handle editing input strings in interactive mode
func terminal_in(text: String) -> void:
	var in_str: String = text
	var echo_text: String = ""
	var buffer_size := _terminal_buffer.size()
	while in_str.length() > 0:
		if in_str.find(ForthTerminal.DEL_LEFT) == 0:
			_pad_position = max(0, _pad_position - 1)
			if _terminal_pad.length():
				# shrink if deleting from end, else replace with space
				if _pad_position == _terminal_pad.length() - 1:
					_terminal_pad = _terminal_pad.left(_pad_position)
				else:
					_terminal_pad[_pad_position] = " "
			# reconstruct the changed entry, with correct cursor position
			echo_text = _refresh_edit_text()
			in_str = in_str.erase(0, ForthTerminal.DEL_LEFT.length())
		elif in_str.find(ForthTerminal.DEL) == 0:
			# do nothing unless cursor is in text
			if _pad_position <= _terminal_pad.length():
				_terminal_pad = _terminal_pad.erase(_pad_position)
			# reconstruct the changed entry, with correct cursor position
			echo_text = _refresh_edit_text()
			in_str = in_str.erase(0, ForthTerminal.DEL.length())
		elif in_str.find(ForthTerminal.LEFT) == 0:
			_pad_position = max(0, _pad_position - 1)
			echo_text = ForthTerminal.LEFT
			in_str = in_str.erase(0, ForthTerminal.LEFT.length())
		elif in_str.find(ForthTerminal.UP) == 0 and buffer_size:
			_buffer_index = max(0, _buffer_index - 1)
			echo_text = _select_buffered_command()
			in_str = in_str.erase(0, ForthTerminal.UP.length())
		elif in_str.find(ForthTerminal.DOWN) == 0 and buffer_size:
			_buffer_index = min(_terminal_buffer.size() - 1, _buffer_index + 1)
			echo_text = _select_buffered_command()
			in_str = in_str.erase(0, ForthTerminal.DOWN.length())
		elif in_str.find(ForthTerminal.LF) == 0:
			echo_text = ""
			in_str = in_str.erase(0, ForthTerminal.LF.length())
		elif in_str.find(ForthTerminal.CR) == 0:
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
			_interpret_terminal_line()
			_terminal_pad = ""
			_pad_position = 0
			in_str = in_str.erase(0, ForthTerminal.CR.length())
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
	terminal_out.emit(BANNER + ForthTerminal.CR + ForthTerminal.LF)
	ram = ForthRAM.new(RAM_SIZE)
	util = ForthUtil.new(self)
	_init_built_ins()
	# set the terminal link in the dictionary
	ram.set_int(_dict_p, -1)
	# reset the buffer pointer
	ram.set_word(BUFF_TO_IN, 0)


# privates


func _abort_line() -> void:
	ram.set_word(BUFF_TO_IN, 0)


func _interpret_terminal_line() -> void:
	var bytes_input: PackedByteArray = _terminal_pad.to_ascii_buffer()
	bytes_input.push_back(0)  # null terminate
	# transfer to the RAM-based input buffer (accessible to the engine)
	for i in bytes_input.size():
		ram.set_byte(BUFF_SOURCE_START + i, bytes_input[i])
	while true:
		# call the Forth WORD, setting blank as delimiter
		_push_word(ForthTerminal.BL.to_ascii_buffer()[0])
		_word()
		_count()
		var len: int = _pop_word()  # length of word
		var caddr: int = _pop_word()  # start of word
		# out of tokens?
		if len == 0:
			# reset the buffer pointer
			_abort_line()
			break
		var t: String = util.str_from_addr_n(caddr, len)
		# t should be the next token
		var found_entry = _find_in_dict(t)
		if found_entry != 0:
			_push_word(found_entry)
			_execute()
		elif t.to_upper() in _built_in_function:
			_built_in_function[t.to_upper()].call()
		# valid numeric value (double first)
		elif t.contains(".") and t.replace(".", "").is_valid_int():
			var t_strip: String = t.replace(".", "")
			var temp: int = t_strip.to_int()
			_push_dword(temp)
		elif t.is_valid_int():
			var temp: int = t.to_int()
			# single-precision
			_push_word(temp)
		# nothing we recognize
		else:
			util.print_unknown_word(t)
			_abort_line()
			return  # not ok
		# check the stack
		if _ds_p < DS_START + DS_WORDS_GUARD:
			util.rprint_term(" Data stack overflow")
			_ds_p = DS_START + DS_WORDS_GUARD
			_abort_line()
			return  # not ok
		if _ds_p > DS_TOP:
			util.rprint_term(" Data stack underflow")
			_ds_p = DS_TOP
			_abort_line()
			return  # not ok
	util.rprint_term(" ok")


# return echo text that refreshes the current edit
func _refresh_edit_text() -> String:
	var echo = (
		ForthTerminal.CLREOL
		+ ForthTerminal.CR
		+ _terminal_pad
		+ ForthTerminal.CR
	)
	for i in range(_pad_position):
		echo += ForthTerminal.RIGHT
	return echo


func _select_buffered_command() -> String:
	var selected_index = _buffer_index
	_terminal_pad = _terminal_buffer[selected_index]
	_pad_position = _terminal_pad.length()
	return ForthTerminal.CLREOL + ForthTerminal.CR + _terminal_pad


func _init_built_ins() -> void:
	var addr: int
	var token_count: int = DICT_VIRTUAL_START
	for i in ForthStdWords.STANDARD_NAMES.size():
		_built_in_address[ForthStdWords.STANDARD_NAMES[i]] = token_count
		token_count += ForthRAM.CELL_SIZE
	for i in _built_in_names.size():
		var word: String = _built_in_names[i][0]
		var f: Callable = _built_in_names[i][1]
		# native functions are assigned virtual addresses, outside of
		# the real memory map.
		addr = _built_in_address[word]
		_built_in_function_from_address[addr] = f
		_address_from_built_in_function[f] = addr
		_built_in_function[word] = f
	# reset token count to point to the EXEC virtual addresses
	token_count = DICT_VIRTUAL_EXEC_START
	for f in _built_in_exec_functions:
		_built_in_function_from_address[token_count] = f
		_address_from_built_in_function[f] = token_count
		token_count += ForthRAM.CELL_SIZE


# Find word in dictionary, starting at address of top
# If found, returns the address of the first code field
# If not found, returns zero
func _find_in_dict(word: String) -> int:
	if _dict_p == _dict_top:
		# dictionary is empty
		return 0
	# stuff the search string in data memory
	util.cstring_from_str(_dict_top, word)
	# make a temporary pointer
	var p: int = _dict_p
	while p != -1:
		_push_word(_dict_top)
		_count()  # search word in addr, n format
		_push_word(p + ForthRAM.CELL_SIZE)
		_count()  # candidate word in addr, n format
		_dup()  # copy the length
		var n_length: int = _pop_word()
		_compare()
		# is this the correct entry?
		if _pop_word() == 0:
			# found it. Link address + link size + string length byte + string
			return p + ForthRAM.CELL_SIZE + 1 + n_length
		# not found, drill down to the next entry
		p = ram.get_int(p)
	# exhausted the dictionary, finding nothing
	return 0


func _push_int(val: int) -> void:
	_ds_p -= ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, val)


func _pop_int() -> int:
	var t: int = ram.get_int(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE
	return t


func _push_word(val: int) -> void:
	_ds_p -= ForthRAM.CELL_SIZE
	ram.set_word(_ds_p, val)


func _pop_word() -> int:
	var t: int = ram.get_word(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE
	return t


func _push_dint(val: int) -> void:
	_ds_p -= ForthRAM.DCELL_SIZE
	ram.set_dint(_ds_p, val)


func _pop_dint() -> int:
	var t: int = ram.get_dint(_ds_p)
	_ds_p += ForthRAM.DCELL_SIZE
	return t


func _push_dword(val: int) -> void:
	_ds_p -= ForthRAM.DCELL_SIZE
	ram.set_dword(_ds_p, val)


func _pop_dword() -> int:
	var t: int = ram.get_dword(_ds_p)
	_ds_p += ForthRAM.DCELL_SIZE
	return t


# built-ins
# Comments
func _left_parenthesis() -> void:
	# Begin parsing a comment, terminated by ')' character
	# ( - )
	_push_word(")".to_ascii_buffer()[0])
	_parse()
	_two_drop()


func _dot_left_parenthesis() -> void:
	# Begin parsing a comment, terminated by ')'. Comment text
	# will emit to the terminal.
	# ( - )
	_push_word(")".to_ascii_buffer()[0])
	_parse()  # returns c-addr n
	_type()


func _back_slash() -> void:
	# Begin parsing a comment, terminated by end of line
	# ( - )
	_push_word(ForthTerminal.CR.to_ascii_buffer()[0])
	_parse()
	_two_drop()


# STACK
func _q_dup() -> void:
	# ( x - 0 | x x )
	var t: int = ram.get_int(_ds_p)
	if t != 0:
		_push_word(t)


func _depth() -> void:
	# ( - +n )
	_push_word((DS_TOP - _ds_p) / ForthRAM.CELL_SIZE)


func _drop() -> void:
	# ( x - )
	_pop_word()


func _dup() -> void:
	# ( x - x x )
	var t: int = ram.get_int(_ds_p)
	_push_word(t)


func _nip() -> void:
	# drop second item, leaving top unchanged
	# ( x1 x2 - x2 )
	var t: int = ram.get_int(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, t)


func _over() -> void:
	# place a copy of x1 on top of the stack
	# ( x1 x2 - x1 x2 x1 )
	_ds_p -= ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, ram.get_int(_ds_p + 2 * ForthRAM.CELL_SIZE))


func _pick() -> void:
	# place a copy of the nth stack entry on top of the stack
	# zeroth item is the top of the stack so 0 pick is dup
	# ( +n - x )
	var t: int = ram.get_int(_ds_p)
	ram.set_int(_ds_p, ram.get_int(_ds_p + (t + 1) * ForthRAM.CELL_SIZE))


func _rot() -> void:
	# rotate the top three items on the stack
	# ( x1 x2 x3 - x2 x3 x1 )
	var t: int = ram.get_int(_ds_p + 2 * ForthRAM.CELL_SIZE)
	ram.set_int(
		_ds_p + 2 * ForthRAM.CELL_SIZE, ram.get_int(_ds_p + ForthRAM.CELL_SIZE)
	)
	ram.set_int(_ds_p + ForthRAM.CELL_SIZE, ram.get_int(_ds_p))
	ram.set_int(_ds_p, t)


func _swap() -> void:
	# exchange the top two items on the stack
	# ( x1 x2 - x2 x1 )
	var t: int = ram.get_int(_ds_p + ForthRAM.CELL_SIZE)
	ram.set_int(_ds_p + ForthRAM.CELL_SIZE, ram.get_int(_ds_p))
	ram.set_int(_ds_p, t)


func _tuck() -> void:
	# place a copy of the top stack item below the second stack item
	# ( x1 x2 - x2 x1 x2 )
	ram.set_int(_ds_p - ForthRAM.CELL_SIZE, ram.get_int(_ds_p))
	ram.set_int(_ds_p, ram.get_int(_ds_p + ForthRAM.CELL_SIZE))
	ram.set_int(
		_ds_p + ForthRAM.CELL_SIZE, ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	)
	_ds_p -= ForthRAM.CELL_SIZE


func _two_drop() -> void:
	# remove the top pair of cells from the stack
	# ( x1 x2 - )
	_pop_dword()


func _two_dup() -> void:
	# duplicate the top cell pair
	# (x1 x2 - x1 x2 x1 x2 )
	var t: int = ram.get_dword(_ds_p)
	_push_dword(t)


func _two_over() -> void:
	# copy a cell pair x1 x2 to the top of the stack
	# ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
	_ds_p -= ForthRAM.DCELL_SIZE
	ram.set_dword(_ds_p, ram.get_dword(_ds_p + 2 * ForthRAM.DCELL_SIZE))


func _two_rot() -> void:
	# rotate the top three cell pairs on the stack
	# ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
	var t: int = ram.get_dword(_ds_p + 2 * ForthRAM.DCELL_SIZE)
	ram.set_dword(
		_ds_p + 2 * ForthRAM.DCELL_SIZE,
		ram.get_dword(_ds_p + ForthRAM.DCELL_SIZE)
	)
	ram.set_dword(_ds_p + ForthRAM.DCELL_SIZE, ram.get_dword(_ds_p))
	ram.set_dword(_ds_p, t)


func _two_swap() -> void:
	# exchange the top two cell pairs
	# ( x1 x2 x3 x4 - x3 x4 x1 x2 )
	var t: int = ram.get_dword(_ds_p + ForthRAM.DCELL_SIZE)
	ram.set_dword(_ds_p + ForthRAM.DCELL_SIZE, ram.get_dword(_ds_p))
	ram.set_dword(_ds_p, t)


# Stack Operations
func _store() -> void:
	# Store x in the cell at a-addr
	# ( x a-addr - )
	var addr: int = _pop_word()
	ram.set_word(addr, _pop_word())


func _fetch() -> void:
	# Replace a-addr with the contents of the cell at a_addr
	# ( a_addr - x )
	_push_word(ram.get_word(_pop_word()))


func _question() -> void:
	# Fetch the contents of the given address and display
	# ( a-addr - )
	_fetch()
	_dot()


# Execution Tokens
func _tick() -> void:
	# Search the dictionary for name and leave its execution token
	# on the stack. Abort if name cannot be found.
	# ( - xt ) <name>
	# retrieve the name token
	_push_word(ForthTerminal.BL.to_ascii_buffer()[0])
	_word()
	_count()
	var len: int = _pop_word()  # length
	var caddr: int = _pop_word()  # start
	var word: String = util.str_from_addr_n(caddr, len)
	# look the name up
	var token_addr = _find_in_dict(word)
	# either in user dictionary, a built-in xt, or neither
	if token_addr:
		_push_word(token_addr)
	elif word in _built_in_address:
		_push_word(_built_in_address[word])
	else:
		util.print_unknown_word(word)


func _execute() -> void:
	# Remove execution token xt from the stack and perform
	# the execution behavior it identifies
	# ( xt - )
	var xt: int = _pop_word()
	if xt in _built_in_function_from_address:
		# this xt identifies a gdscript function
		_built_in_function_from_address[xt].call()
	elif xt >= DICT_START and xt < DICT_TOP:
		# this is a physical address of an xt
		_dict_ip = xt
		# push the xt
		_push_word(ram.get_word(xt))
		# recurse down a layer
		_execute()
	else:
		util.rprint_term(" Invalid execution token")


# Programmer Conveniences
func _dot_s() -> void:
	var pointer = DS_TOP - ForthRAM.CELL_SIZE
	util.rprint_term("")
	while pointer >= _ds_p:
		util.print_term(" " + str(ram.get_int(pointer)))
		pointer -= ForthRAM.CELL_SIZE
	util.print_term(" <-Top")


func _dot() -> void:
	util.print_term(" " + str(_pop_int()))


func _d_dot() -> void:
	util.print_term(" " + str(_pop_dint()))


func _star() -> void:
	# Multiply n1 by n2 leaving the product n3
	# ( n1 n2 - n3 )
	var t: int = ram.get_int(_ds_p) * ram.get_int(_ds_p + ForthRAM.CELL_SIZE)
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, t)


func _star_slash() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell quotient n4.
	# ( n1 n2 n3 - n4 )
	var p: int = (
		ram.get_int(_ds_p + ForthRAM.CELL_SIZE)
		* ram.get_int(_ds_p + ForthRAM.CELL_SIZE * 2)
	)
	var q: int = p / ram.get_int(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE * 2
	ram.set_int(_ds_p, q)


func _star_slash_mod() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell remainder n4
	# and a single-cell quotient n5
	# ( n1 n2 n3 - n4 n5 )
	var p: int = (
		ram.get_int(_ds_p + ForthRAM.CELL_SIZE)
		* ram.get_int(_ds_p + ForthRAM.CELL_SIZE * 2)
	)
	var r: int = p % ram.get_int(_ds_p)
	var q: int = p / ram.get_int(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, q)  # quotient
	ram.set_int(_ds_p + ForthRAM.CELL_SIZE, r)  # remainder


func _plus() -> void:
	# Add n1 to n2 leaving the sum n3
	# ( n1 n2 - n3 )
	var t: int = ram.get_int(_ds_p) + ram.get_int(_ds_p + ForthRAM.CELL_SIZE)
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, t)


func _minus() -> void:
	# subtract n2 from n1, leaving the diference n3
	# ( n1 n2 - n3 )
	var t: int = ram.get_int(_ds_p + ForthRAM.CELL_SIZE) - ram.get_int(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, t)


func _slash() -> void:
	# divide n1 by n2, leaving the quotient n3
	# ( n1 n2 - n3 )
	var t: int = ram.get_int(_ds_p + ForthRAM.CELL_SIZE) / ram.get_int(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, t)


func _slash_mod() -> void:
	# divide n1 by n2, leaving the remainder n3 and quotient n4
	# ( n1 n2 - n3 n4 )
	var q: int = ram.get_int(_ds_p + ForthRAM.CELL_SIZE) / ram.get_int(_ds_p)
	var r: int = ram.get_int(_ds_p + ForthRAM.CELL_SIZE) % ram.get_int(_ds_p)
	ram.set_int(_ds_p, q)
	ram.set_int(_ds_p + ForthRAM.CELL_SIZE, r)


func _one_plus() -> void:
	# Add one to n1, leaving n2
	# ( n1 - n2 )
	ram.set_int(_ds_p, ram.get_int(_ds_p) + 1)


func _one_minus() -> void:
	# Subtract one from n1, leaving n2
	# ( n1 - n2 )
	ram.set_int(_ds_p, ram.get_int(_ds_p) - 1)


func _two_plus() -> void:
	# Add two to n1, leaving n2
	# ( n1 - n2 )
	ram.set_int(_ds_p, ram.get_int(_ds_p) + 2)


func _two_minus() -> void:
	# Subtract two from n1, leaving n2
	# ( n1 - n2 )
	ram.set_int(_ds_p, ram.get_int(_ds_p) - 2)


func _two_star() -> void:
	# Return x2, result of shifting x1 one bit towards the MSB,
	# filling the LSB with zero
	# ( x1 - x2 )
	ram.set_int(_ds_p, ram.get_int(_ds_p) << 1)


func _two_slash() -> void:
	# Return x2, result of shifting x1 one bit towards LSB,
	# leaving the MSB unchanged
	# ( x1 - x2 )
	ram.set_int(_ds_p, ram.get_int(_ds_p) >> 1)


func _lshift() -> void:
	# Perform a logical left shift of u places on x1, giving x2._add_constant_central_force
	# Fill the vacated LSB bits with zero
	# (x1 u - x2 )
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(
		_ds_p, ram.get_int(_ds_p) << ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	)


func _mod() -> void:
	# Divide n1 by n2, giving the remainder n3
	# (n1 n2 - n3 )
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(
		_ds_p, ram.get_int(_ds_p) % ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	)


func _rshift() -> void:
	# Perform a logical right shift of u places on x1, giving x2.
	# Fill the vacated MSB bits with zeroes
	# ( x1 u - x2 )
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_int(
		_ds_p, ram.get_word(_ds_p) >> ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	)


func _d_plus() -> void:
	# Add d1 to d2, leaving the sum d3
	# ( d1 d2 - d3 )
	_ds_p += ForthRAM.DCELL_SIZE
	ram.set_dint(
		_ds_p, ram.get_dint(_ds_p) + ram.get_dint(_ds_p - ForthRAM.DCELL_SIZE)
	)


func _d_minus() -> void:
	# Subtract d2 from d1, leaving the difference d3
	# ( d1 d2 - d3 )
	_ds_p += ForthRAM.DCELL_SIZE
	ram.set_dint(
		_ds_p, ram.get_dint(_ds_p) - ram.get_dint(_ds_p - ForthRAM.DCELL_SIZE)
	)


func _d_two_star() -> void:
	# Multiply d1 by 2, leaving the result d2
	# ( d1 - d2 )
	ram.set_dint(_ds_p, ram.get_dint(_ds_p) * 2)


func _d_two_slash() -> void:
	# Divide d1 by 2, leaving the result d2
	# ( d1 - d2 )
	ram.set_dint(_ds_p, ram.get_dint(_ds_p) / 2)


func _d_to_s() -> void:
	# Convert double to single, discarding MS cell.
	# ( d - n )
	# this assumes doubles are pushed in LS MS order
	_pop_int()


func _m_star() -> void:
	# Multiply n1 by n2, leaving the double result d.
	# ( n1 n2 - d )
	ram.set_dint(
		_ds_p, ram.get_int(_ds_p) * ram.get_int(_ds_p + ForthRAM.CELL_SIZE)
	)


func _m_star_slash() -> void:
	# Multiply d1 by n1 producing a triple cell intermediate result t.
	# Divide t by n2, giving quotient d2.
	# Use this with n1 or n2 = 1 to accomplish double precision multiplication
	# or division.
	# ( d1 n1 +n2 - d2 )
	# Following is an *approximate* implementation, using the double float
	var q: float = (
		float(ram.get_int(_ds_p + ForthRAM.CELL_SIZE)) / ram.get_int(_ds_p)
	)
	_ds_p += ForthRAM.CELL_SIZE * 2
	ram.set_dint(_ds_p, ram.get_dint(_ds_p) * q)


func _m_plus() -> void:
	# Add n to d1 leaving the sum d2
	# ( d1 n - d2 )
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_dint(
		_ds_p, ram.get_dint(_ds_p) + ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	)


func _m_minus() -> void:
	# Subtract n from d1 leaving the difference d2
	# ( d1 n - d2 )
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_dint(
		_ds_p, ram.get_dint(_ds_p) - ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	)


func _m_slash() -> void:
	# Divide d by n1 leaving the single precision quotient n2
	# ( d n1 - n2 )
	var t: int = ram.get_dint(_ds_p + ForthRAM.CELL_SIZE) / ram.get_int(_ds_p)
	_ds_p += ForthRAM.DCELL_SIZE
	ram.set_int(_ds_p, t)


func _s_to_d() -> void:
	# Convert a single cell number n to its double equivalent d
	# ( n - d )
	var t: int = ram.get_int(_ds_p)
	_ds_p += ForthRAM.CELL_SIZE - ForthRAM.DCELL_SIZE
	ram.set_dint(_ds_p, t)


func _sm_slash_rem() -> void:
	# Divide d by n1, using symmetric division, giving quotient n3 and
	# remainder n2. All arguments are signed.
	# ( d n1 - n2 n3 )
	var dd: int = ram.get_dint(_ds_p + ForthRAM.CELL_SIZE)
	var d: int = ram.get_int(_ds_p)
	var q: int = dd / d
	var r: int = dd % d
	_ds_p += ForthRAM.DCELL_SIZE - ForthRAM.CELL_SIZE
	ram.set_int(_ds_p, q)
	ram.set_int(_ds_p + ForthRAM.CELL_SIZE, r)


func _um_slash_mod() -> void:
	# Divide ud by n1, leaving quotient n3 and remainder n2.
	# All arguments and result are unsigned.
	# ( d u1 - u2 u3 )
	var dd: int = ram.get_dword(_ds_p + ForthRAM.CELL_SIZE)
	var d: int = ram.get_word(_ds_p)
	var q: int = dd / d
	var r: int = dd % d
	_ds_p += ForthRAM.DCELL_SIZE - ForthRAM.CELL_SIZE
	ram.set_word(_ds_p, q)
	ram.set_word(_ds_p + ForthRAM.CELL_SIZE, r)


func _um_star() -> void:
	# Multiply u1 by u2, leaving the double-precision result ud
	# ( u1 u2 - ud )
	ram.set_dword(
		_ds_p, ram.get_word(_ds_p + ForthRAM.CELL_SIZE) * ram.get_word(_ds_p)
	)


# Logical Operators
func _abs() -> void:
	# Replace the top stack item with its absolute value
	# ( n - +n )
	ram.set_word(_ds_p, abs(ram.get_int(_ds_p)))


func _and() -> void:
	# Return x3, the bit-wise logical and of x1 and x2
	# ( x1 x2 - x3)
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_word(
		_ds_p, ram.get_word(_ds_p) & ram.get_word(_ds_p - ForthRAM.CELL_SIZE)
	)


func _invert() -> void:
	# Invert all bits of x1, giving its logical inverse x2
	# ( x1 - x2 )
	ram.set_word(_ds_p, ~ram.get_word(_ds_p))


func _max() -> void:
	# Return n3, the greater of n1 and n2
	# ( n1 n2 - n3 )
	_ds_p += ForthRAM.CELL_SIZE
	var lt: bool = ram.get_int(_ds_p) < ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	if lt:
		ram.set_int(_ds_p, ram.get_int(_ds_p - ForthRAM.CELL_SIZE))


func _min() -> void:
	# Return n3, the lesser of n1 and n2
	# ( n1 n2 - n3 )
	_ds_p += ForthRAM.CELL_SIZE
	var gt: bool = ram.get_int(_ds_p) > ram.get_int(_ds_p - ForthRAM.CELL_SIZE)
	if gt:
		ram.set_int(_ds_p, ram.get_int(_ds_p - ForthRAM.CELL_SIZE))


func _negate() -> void:
	# Change the sign of the top stack value
	# ( n - -n )
	ram.set_int(_ds_p, -ram.get_int(_ds_p))


func _or() -> void:
	# Return x3, the bit-wise inclusive or of x1 with x2
	# ( x1 x2 - x3 )
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_word(
		_ds_p, ram.get_word(_ds_p) | ram.get_word(_ds_p - ForthRAM.CELL_SIZE)
	)


func _xor() -> void:
	# Return x3, the bit-wise exclusive or of x1 with x2
	# ( x1 x2 - x3 )
	_ds_p += ForthRAM.CELL_SIZE
	ram.set_word(
		_ds_p, ram.get_word(_ds_p) ^ ram.get_word(_ds_p - ForthRAM.CELL_SIZE)
	)


# Double-Precision Logical Operators
func _d_abs() -> void:
	# Replace the top stack item with its absolute value
	# ( d - +d )
	ram.set_dword(_ds_p, abs(ram.get_dint(_ds_p)))


func _d_max() -> void:
	# Return d3, the greater of d1 and d2
	# ( d1 d2 - d3 )
	_ds_p += ForthRAM.DCELL_SIZE
	if ram.get_dint(_ds_p) < ram.get_dint(_ds_p - ForthRAM.DCELL_SIZE):
		ram.set_dint(_ds_p, ram.get_dint(_ds_p - ForthRAM.DCELL_SIZE))


func _d_min() -> void:
	# Return d3, the lesser of d1 and d2
	# ( d1 d2 - d3 )
	_ds_p += ForthRAM.DCELL_SIZE
	if ram.get_dint(_ds_p) > ram.get_dint(_ds_p - ForthRAM.DCELL_SIZE):
		ram.set_dint(_ds_p, ram.get_dint(_ds_p - ForthRAM.DCELL_SIZE))


func _d_negate() -> void:
	# Change the sign of the top stack value
	# ( d - -d )
	ram.set_dword(_ds_p, -ram.get_dint(_ds_p))


# Input
func _word() -> void:
	# Skip leading occurrences of the delimiter char. Parse text
	# deliminted by char. Return the address of a temporary location
	# containing the pased text as a counted string
	# ( char - c-addr )
	_dup()
	var delim: int = _pop_word()
	_source()
	var source_size: int = _pop_word()
	var source_start: int = _pop_word()
	_to_in()
	var ptraddr: int = _pop_word()
	while true:
		var t: int = ram.get_byte(source_start + ram.get_word(ptraddr))
		if t == delim:
			# increment the input pointer
			ram.set_word(ptraddr, ram.get_word(ptraddr) + 1)
		else:
			break
	_parse()
	var count: int = _pop_word()
	var straddr: int = _pop_word()
	var ret: int = straddr - 1
	ram.set_byte(ret, count)
	_push_word(ret)


func _parse() -> void:
	# Parse text to the first instance of char, returning the address
	# and length of a temporary location containing the parsed text.
	# Returns an address with one byte available in front for forming
	# a character count. Consumes the final delimiter.
	# ( char - c_addr n )
	var count: int = 0
	var ptr: int = WORD_START + 1
	var delim: int = _pop_word()
	_source()
	var source_size: int = _pop_word()
	var source_start: int = _pop_word()
	_to_in()
	var ptraddr: int = _pop_word()
	_push_word(ptr)  # parsed text begins here
	while true:
		var t: int = ram.get_byte(source_start + ram.get_word(ptraddr))
		# increment the input pointer
		if t != 0:
			ram.set_word(ptraddr, ram.get_word(ptraddr) + 1)
		# a null character also stops the parse
		if t != 0 and t != delim:
			ram.set_byte(ptr, t)
			ptr += 1
			count += 1
		else:
			break
	_push_word(count)


func _b_l() -> void:
	# Return char, the ASCII character value of a space
	# ( - char )
	_push_word(int(ForthTerminal.BL))


func _to_in() -> void:
	# Return address of a cell containing the offset, in characters,
	# from the start of the input buffer to the start of the current
	# parse position
	# ( - a-addr )
	_push_word(BUFF_TO_IN)


func _source() -> void:
	# Return the address and length of the input buffer
	# ( - c-addr u )
	_push_word(BUFF_SOURCE_START)
	_push_word(BUFF_SOURCE_SIZE)


# Strings


func _count() -> void:
	# Return the length n, and address of the text portion of a counted string
	# ( c_addr1 - c_addr2 u )
	var addr: int = _pop_word()
	_push_word(addr + 1)
	_push_word(ram.get_byte(addr))


func _compare() -> void:
	# Compare string to string (see details in docs)
	# ( c-addr1 u1 c-addr2 u2 - n )
	var n2: int = _pop_word()
	var a2: int = _pop_word()
	var n1: int = _pop_word()
	var a1: int = _pop_word()
	var s2: String = util.str_from_addr_n(a2, n2)
	var s1: String = util.str_from_addr_n(a1, n1)
	var ret: int = 0
	if s1 == s2:
		_push_word(ret)
	elif s1 < s2:
		_push_word(-1)
	else:
		_push_word(1)


func _here() -> void:
	# Return address of the next available location in data-space
	# ( - addr )
	_push_word(_dict_top)


func _move() -> void:
	# Copy u byes from a source starting at addr1 to the destination
	# starting at addr2. This works even if the ranges overlap.
	# ( addr1 addr2 u - )
	var a1: int = ram.get_word(_ds_p + 2 * ForthRAM.CELL_SIZE)
	var a2: int = ram.get_word(_ds_p + ForthRAM.CELL_SIZE)
	var u: int = ram.get_word(_ds_p)
	if a1 == a2 or u == 0:
		# string doesn't need to move. Clean the stack and return.
		_drop()
		_two_drop()
		return
	if a1 > a2:
		# potentially overlapping, source above dest
		_c_move()
	else:
		# potentially overlapping, source below dest
		_c_move_up()


func _c_move() -> void:
	# Copy u characters from addr1 to addr2. The copy proceeds from
	# LOWER to HIGHER addresses.
	# ( addr1 addr2 u - )
	var u: int = _pop_word()
	var a2: int = _pop_word()
	var a1: int = _pop_word()
	var i: int = 0
	# move in ascending order a1 -> a2, fast, then slow
	while i < u:
		if u - i >= ForthRAM.DCELL_SIZE:
			ram.set_dword(a2 + i, ram.get_dword(a1 + i))
			i += ForthRAM.DCELL_SIZE
		else:
			ram.set_byte(a2 + i, ram.get_byte(a1 + i))
			i += 1


func _c_move_up() -> void:
	# Copy u characters from addr1 to addr2. The copy proceeds from
	# HIGHER to LOWER addresses.
	# ( addr1 addr2 u - )
	var u: int = _pop_word()
	var a2: int = _pop_word()
	var a1: int = _pop_word()
	var i: int = u
	# move in descending order a1 -> a2, fast, then slow
	while i > 0:
		if i >= ForthRAM.DCELL_SIZE:
			i -= ForthRAM.DCELL_SIZE
			ram.set_dword(a2 + i, ram.get_dword(a1 + i))
		else:
			i -= 1
			ram.set_byte(a2 + i, ram.get_byte(a1 + i))


# Arrays


func _comma() -> void:
	# Reserve one cell of data space and store x in it.
	# ( x - )
	ram.set_word(_dict_top, _pop_word())
	_dict_top += ForthRAM.CELL_SIZE


func _allot() -> void:
	# Allocate u bytes of data space beginning at the next location.
	# ( u - )
	_dict_top += _pop_word()


func _buffer_colon() -> void:
	# Create a dictionary entry for name associated with n bytes of space
	# n BUFFER: <name>
	# ( n - )
	# execution of <name> will return address of the starting byte ( - addr )
	_create()
	_allot()


func _c_comma() -> void:
	# Rserve one byte of data space and store char in the byte
	# ( char - )
	ram.set_byte(_dict_top, _pop_word())
	_dict_top += 1


func _cell_plus() -> void:
	# Add the size in bytes of a cell to a_addr1, returning a_addr2
	# ( a-addr1 - a-addr2 )
	_push_word(ForthRAM.CELL_SIZE)
	_plus()


func _cells() -> void:
	# Return n2, the size in bytes of n1 cells
	# ( n1 - n2 )
	_push_word(ForthRAM.CELL_SIZE)
	_star()


func _char_plus() -> void:
	# Add the size in bytes of a character to c_addr1, giving c-addr2
	# ( c-addr1 - c-addr2 )
	_push_word(1)
	_plus()


func _chars() -> void:
	# Return n2, the size in bytes of n1 characters. May be a no-op.
	pass


# Defining Words


func _words() -> void:
	# List all the definition names in the word list of the search order.
	# Returns dictionary names, then built-in names.
	# ( - )
	var word_len: int
	var col: int = "WORDS".length() + 1
	util.print_term(" ")
	if _dict_p != _dict_top:
		# dictionary is not empty
		var p: int = _dict_p
		while p != -1:
			_push_word(p + ForthRAM.CELL_SIZE)
			_count()  # search word in addr, n format
			_dup()  # retrieve the size
			word_len = _pop_word()
			if col + word_len + 1 >= ForthTerminal.COLUMNS - 2:
				util.print_term(ForthTerminal.CRLF)
				col = 0
			col += word_len + 1
			# emit the dictionary entry name
			_type()
			util.print_term(" ")
			# drill down to the next entry
			p = ram.get_int(p)
	# now go through the built-in names
	for entry in _built_in_names:
		word_len = entry[0].length()
		if col + word_len + 1 >= ForthTerminal.COLUMNS - 2:
			util.print_term(ForthTerminal.CRLF)
			col = 0
		col += word_len + 1
		util.print_term(entry[0] + " ")


func _create_dict_entry_name() -> void:
	# Internal utility function for creating the start of
	# a dictionary entry. The next thing to follow will be
	# the execution token. Upon exit, _dict_top will point to the
	# next byte in the entry.
	# ( - )
	# Grab the name
	_push_word(ForthTerminal.BL.to_ascii_buffer()[0])
	_word()
	_count()
	var len: int = _pop_word()  # length
	var caddr: int = _pop_word()  # start
	# poke address of last link at next spot, but only if this isn't
	# the very first spot in the dictionary
	if _dict_top != _dict_p:
		ram.set_word(_dict_top, _dict_p)
	# move the top link
	_dict_p = _dict_top
	_dict_top += ForthRAM.CELL_SIZE
	# poke the name length
	ram.set_byte(_dict_top, len)
	_dict_top += 1
	# copy the name
	_push_word(caddr)
	_push_word(_dict_top)
	_push_word(len)
	_move()
	_dict_top += len


func _create() -> void:
	# Construct a dictionary entry for the next token in the input stream
	# Execution of *name* will return the address of its data space
	# ( - )
	_create_dict_entry_name()
	ram.set_word(_dict_top, _address_from_built_in_function[_create_exec])
	_dict_top += ForthRAM.CELL_SIZE


func _create_exec() -> void:
	# execution time functionality of _create
	# return address of cell after execution token
	_push_word(_dict_ip + ForthRAM.CELL_SIZE)


func _variable() -> void:
	# Create a dictionary entry for name associated with one cell of data
	# ( - )
	_create()
	# make room for one cell
	_dict_top += ForthRAM.CELL_SIZE


func _two_variable() -> void:
	# Create a ditionary entry for name associated with two cells of data
	# ( - )
	_create()
	# make room for one cell
	_dict_top += ForthRAM.DCELL_SIZE


func _constant() -> void:
	# Create a dictionary entry for name, associated with constant x.
	# ( x - )
	_create_dict_entry_name()
	# copy the execution token
	ram.set_word(_dict_top, _address_from_built_in_function[_constant_exec])
	# store the constant
	ram.set_word(_dict_top + ForthRAM.CELL_SIZE, _pop_word())
	_dict_top += ForthRAM.DCELL_SIZE  # two cells up


func _constant_exec() -> void:
	# execution time functionality of _constant
	# return contents of cell after execution token
	_push_word(ram.get_word(_dict_ip + ForthRAM.CELL_SIZE))


func _two_constant() -> void:
	# Create a dictionary entry for name, associated with constant double d.
	# ( d - )
	_create_dict_entry_name()
	# copy the execution token
	ram.set_word(_dict_top, _address_from_built_in_function[_two_constant_exec])
	# store the constant
	ram.set_dword(_dict_top + ForthRAM.CELL_SIZE, _pop_dword())
	_dict_top += ForthRAM.CELL_SIZE + ForthRAM.DCELL_SIZE


func _two_constant_exec() -> void:
	# execution time functionality of _two_constant
	# return contents of double cell after execution token
	_push_dword(ram.get_dword(_dict_ip + ForthRAM.CELL_SIZE))


func _value() -> void:
	# Create a dictionary entry for name, associated with value x.
	# ( x - )
	_create_dict_entry_name()
	# copy the execution token
	ram.set_word(_dict_top, _address_from_built_in_function[_value_exec])
	# store the initial value
	ram.set_word(_dict_top + ForthRAM.CELL_SIZE, _pop_word())
	_dict_top += ForthRAM.DCELL_SIZE


func _value_exec() -> void:
	# execution time functionality of _value
	# return contents of the cell after the execution token
	_push_word(ram.get_word(_dict_ip + ForthRAM.CELL_SIZE))


func _to() -> void:
	# Store x in the data space associated with name (defined by value)
	# x TO <name> ( x - )
	# get the name
	_push_word(ForthTerminal.BL.to_ascii_buffer()[0])
	_word()
	_count()
	var len: int = _pop_word()  # length
	var caddr: int = _pop_word()  # start
	var word: String = util.str_from_addr_n(caddr, len)
	var token_addr = _find_in_dict(word)
	if not token_addr:
		util.print_unknown_word(word)
	else:
		# adjust to data field location
		token_addr += ForthRAM.CELL_SIZE
		ram.set_word(token_addr, _pop_word())


# Dictionary


func _unused() -> void:
	# Return u, the number of bytes remaining in the memory area
	# where dictionary entries are constructed.
	# ( - u )
	_push_word(DICT_TOP - _dict_top)


# Terminal I/O
func _emit() -> void:
	# Output one character from the LSB of the top item on stack.
	# ( b - )
	var c: int = _pop_word()
	util.print_term(char(c))


func _type() -> void:
	# Output the characer string at c-addr, length u
	# ( c-addr u - )
	var l: int = _pop_word()
	var s: int = _pop_word()
	for i in l:
		_push_word(ram.get_byte(s + i))
		_emit()

# gdlint:ignore = max-file-lines
