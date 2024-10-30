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
# cell size should be 2 or 4
# if 2, use (encode|decode)_(s|u)16 and (encode|decode)_(s_u)32
# if 4, use (encode|decode)_(s|u)32 and (encode|decode)_(s_u)64
const DS_CELL_SIZE := 4
const DS_DCELL_SIZE := DS_CELL_SIZE * 2
const DS_TOP := DS_START + DS_WORDS_SIZE * DS_CELL_SIZE
# Control Stack
const CS_START := DS_TOP + DS_WORDS_GUARD * DS_CELL_SIZE  # start of control stack
const CS_WORDS_SIZE := 0x020
const CS_CELL_SIZE := 4
const CS_TOP := CS_START + CS_WORDS_SIZE * CS_CELL_SIZE
# Input Buffer
const BUFF_SOURCE_SIZE := 0x0100  # bytes
const BUFF_SOURCE_START := CS_TOP
const BUFF_SOURCE_TOP := BUFF_SOURCE_START + BUFF_SOURCE_SIZE
# Pointer to the parse position in the buffer
const BUFF_TO_IN := BUFF_SOURCE_TOP
const BUFF_TO_IN_TOP := BUFF_TO_IN + DS_CELL_SIZE
# Temporary word storage (used by WORD)
const WORD_SIZE := 0x0100
const WORD_START := BUFF_TO_IN_TOP
const WORD_TOP := WORD_START + WORD_SIZE

# VIRTUAL addresses for built-in words
const DICT_VIRTUAL_START := 0x0f000000

const TRUE := int(-1)
const FALSE := int(0)

const TERM_BSP := char(0x08)
const TERM_CR := char(0x0D)
const TERM_LF := char(0x0A)
const TERM_ESC := char(0x1B)
const TERM_DEL_LEFT := char(0x7F)
const TERM_BL := char(0x20)
const TERM_DEL := TERM_ESC + "[3~"
const TERM_UP := TERM_ESC + "[A"
const TERM_DOWN := TERM_ESC + "[B"
const TERM_RIGHT := TERM_ESC + "[C"
const TERM_LEFT := TERM_ESC + "[D"
const TERM_CLREOL := TERM_ESC + "[2K"
const MAX_BUFFER_SIZE := 20

const DEFINING_NAMES = [
	"CREATE",
	"VARIABLE",
	"2VARIABLE",
	"CVARIABLE",
]

# Built-In names have a run-time definition and optional
# compile-time definition
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
	# Stack Operations
	["!", _store],
	["@", _fetch],
	# Execution Tokens
	["'", _tick],
	["EXECUTE", _execute],
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
	# Double-Precision Logical Operators
	["DABS", _d_abs],
	["DMAX", _d_max],
	["DMIN", _d_min],
	["DNEGATE", _d_negate],
	# Input
	["WORD", _word],
	["PARSE", _parse],
	["BL", _b_l],
	[">IN", _to_in],
	["SOURCE", _source],
	# Defining Words
	["CREATE", _create],
	#["VARIABLE", _variable, _ct_variable],
	#["2VARIABLE", _two_variable, _ct_two_variable],
	#["CVARIABLE", _c_variable, _ct_c_variable],
	# Strings
	["COUNT", _count],
	["COMPARE", _compare],
	["HERE", _here],
	["MOVE", _move],
	["CMOVE", _c_move],
	["CMOVE>", _c_move_up],
	# Dictionary
	["ALLOT", _allot],
	["UNUSED", _unused],
]

# get built-in "address" from word
var _built_in_address: Dictionary = {}
# get built-in function from word
var _built_in_function: Dictionary = {}
# get built-in function from "address"
var _built_in_function_from_address: Dictionary = {}

# execution token allocation
var _token_count = DICT_VIRTUAL_START

# The Forth dictionary space
var _dict_p := DICT_START  # position of last link
var _dict_top := DICT_START  # position of next new link to create
var _dict_ip := 0  # code field pointer set to current execution point

# The Forth data stack pointer is in byte units
var _ds_p := DS_TOP
var _ram := PackedByteArray()

# terminal scratchpad and buffer
var _terminal_pad: String = ""
var _pad_position := 0
var _parse_pointer := 0
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
			_interpret_terminal_line()
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


# gdscript String from address and length
func _str_from_addr_n(addr: int, n: int) -> String:
	var t: String = ""
	for c in n:
		t = t + char(_get_byte(addr + c))
	return t


# Execute the code field at address. This will recurse down
# until it executes a built-in
func _execute_code_field(addr: int) -> void:
	var code_word: int = _get_word(addr)
	var f:Callable = _built_in_function_from_address.get(code_word)
	if f:
		# _dict_ip = addr # FIXME not really needed?
		f.call()
	else:
		# the code word is an address somewhere else
		_execute_code_field(code_word)


# counted string from gdscript String
func _cstring_from_str(addr: int, s: String) -> void:
	var n: int = addr
	_set_byte(n, s.length())
	n += 1
	for c in s.to_ascii_buffer():
		_set_byte(n, c)
		n += 1


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


func _interpret_terminal_line() -> void:
	var tokens: PackedStringArray = _terminal_pad.split(" ")
	while tokens.has(""):
		tokens.remove_at(tokens.find(""))
	tokens = _strip_comments(tokens)
	# reassemble input stream
	var stripped_input := " ".join(tokens)
	var bytes_input: PackedByteArray = (
		stripped_input.to_upper().to_ascii_buffer()
	)
	bytes_input.push_back(0)  # null terminate
	# transfer to the RAM-based input buffer (accessible to the engine)
	for i in bytes_input.size():
		_set_byte(BUFF_SOURCE_START + i, bytes_input[i])
	# reset the buffer pointer
	_set_word(BUFF_TO_IN, 0)
	while true:
		# call the Forth WORD, setting blank as delimiter
		_push_word(TERM_BL.to_ascii_buffer()[0])
		_word()
		_count()
		var len: int = _pop_word()  # length of word
		var caddr: int = _pop_word()  # start of word
		# out of tokens?
		if len == 0:
			break
		var t: String = _str_from_addr_n(caddr, len)
		# t should be the next token
		if t in _built_in_function:
			_built_in_function[t].call()
		else:
			var found_entry = _find_in_dict(t)
			if found_entry != 0:
				_execute_code_field(found_entry)
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


# allocate a virtual execution token to a specific function
# returns the token
func _allocate_execution_token(f:Callable) -> int:
	# assign the function to the current token
	_built_in_function_from_address[_token_count] = f
	var ret:int = _token_count
	_token_count += DS_CELL_SIZE
	return ret

func _init_built_ins() -> void:
	for i in _built_in_names.size():
		var word: String = _built_in_names[i][0]
		var f: Callable = _built_in_names[i][1]
		# native functions are assigned virtual addresses, outside of
		# the real memory map.
		var addr:int = _allocate_execution_token(f)
		_built_in_address[word] = addr
		_built_in_function[word] = f


# Find word in dictionary, starting at address of top
# If found, returns the address of the first code field
# If not found, returns zero
func _find_in_dict(word: String) -> int:
	if _dict_p == _dict_top:
		# dictionary is empty
		return 0
	# stuff the search string in data memory
	_cstring_from_str(_dict_top, word)
	# make a temporary pointer
	var p: int = _dict_p
	while p != -1:
		_push_word(_dict_top)
		_count()  # search word in addr, n format
		_push_word(p + DS_CELL_SIZE)
		_count()  # candidate word in addr, n format
		_dup()  # copy the length
		var n_length: int = _pop_word()
		_compare()
		# is this the correct entry?
		if _pop_word() == 0:
			# found it. Link address + link size + string length byte + string
			return p + DS_CELL_SIZE + 1 + n_length
		# not found, drill down to the next entry
		p = _get_int(p)
	# exhausted the dictionary, finding nothing
	return 0


# Data stack and RAM helpers
func _set_byte(addr: int, val: int) -> void:
	_ram.encode_u8(addr, val)


func _get_byte(addr: int) -> int:
	return _ram.decode_u8(addr)


# signed cell-sized values


func _set_int(addr: int, val: int) -> void:
	_ram.encode_s32(addr, val)


func _push_int(val: int) -> void:
	_ds_p -= DS_CELL_SIZE
	_set_int(_ds_p, val)


func _get_int(addr: int) -> int:
	return _ram.decode_s32(addr)


func _pop_int() -> int:
	var t: int = _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE
	return t


# unsigned cell-sized values


func _set_word(addr: int, val: int) -> void:
	_ram.encode_u32(addr, val)


func _push_word(val: int) -> void:
	_ds_p -= DS_CELL_SIZE
	_set_word(_ds_p, val)


func _get_word(addr: int) -> int:
	return _ram.decode_u32(addr)


func _pop_word() -> int:
	var t: int = _get_word(_ds_p)
	_ds_p += DS_CELL_SIZE
	return t


# signed double-precision values


func _set_dint(addr: int, val: int) -> void:
	_ram.encode_s64(addr, _d_swap(val))


func _push_dint(val: int) -> void:
	_ds_p -= DS_DCELL_SIZE
	_set_dint(_ds_p, val)


func _get_dint(addr: int) -> int:
	return _d_swap(_ram.decode_s64(addr))


func _pop_dint() -> int:
	var t: int = _get_dint(_ds_p)
	_ds_p += DS_DCELL_SIZE
	return t


# unsigned double-precision values


func _set_dword(addr: int, val: int) -> void:
	_ram.encode_u64(addr, _d_swap(val))


func _push_dword(val: int) -> void:
	_ds_p -= DS_DCELL_SIZE
	_set_dword(_ds_p, val)


func _get_dword(addr: int) -> int:
	return _d_swap(_ram.decode_u64(addr))


func _pop_dword() -> int:
	var t: int = _get_dword(_ds_p)
	_ds_p += DS_DCELL_SIZE
	return t


# built-ins
# STACK
func _q_dup() -> void:
	# ( x - 0 | x x )
	var t: int = _get_int(_ds_p)
	if t != 0:
		_push_word(t)


func _depth() -> void:
	# ( - +n )
	_push_word((DS_TOP - _ds_p) / DS_CELL_SIZE)


func _drop() -> void:
	# ( x - )
	_pop_word()


func _dup() -> void:
	# ( x - x x )
	var t: int = _get_int(_ds_p)
	_push_word(t)


func _nip() -> void:
	# drop second item, leaving top unchanged
	# ( x1 x2 - x2 )
	var t: int = _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, t)


func _over() -> void:
	# place a copy of x1 on top of the stack
	# ( x1 x2 - x1 x2 x1 )
	_ds_p -= DS_CELL_SIZE
	_set_int(_ds_p, _get_int(_ds_p + 2 * DS_CELL_SIZE))


func _pick() -> void:
	# place a copy of the nth stack entry on top of the stack
	# zeroth item is the top of the stack so 0 pick is dup
	# ( +n - x )
	var t: int = _get_int(_ds_p)
	_set_int(_ds_p, _get_int(_ds_p + (t + 1) * DS_CELL_SIZE))


func _rot() -> void:
	# rotate the top three items on the stack
	# ( x1 x2 x3 - x2 x3 x1 )
	var t: int = _get_int(_ds_p + 2 * DS_CELL_SIZE)
	_set_int(_ds_p + 2 * DS_CELL_SIZE, _get_int(_ds_p + DS_CELL_SIZE))
	_set_int(_ds_p + DS_CELL_SIZE, _get_int(_ds_p))
	_set_int(_ds_p, t)


func _swap() -> void:
	# exchange the top two items on the stack
	# ( x1 x2 - x2 x1 )
	var t: int = _get_int(_ds_p + DS_CELL_SIZE)
	_set_int(_ds_p + DS_CELL_SIZE, _get_int(_ds_p))
	_set_int(_ds_p, t)


func _tuck() -> void:
	# place a copy of the top stack item below the second stack item
	# ( x1 x2 - x2 x1 x2 )
	_set_int(_ds_p - DS_CELL_SIZE, _get_int(_ds_p))
	_set_int(_ds_p, _get_int(_ds_p + DS_CELL_SIZE))
	_set_int(_ds_p + DS_CELL_SIZE, _get_int(_ds_p - DS_CELL_SIZE))
	_ds_p -= DS_CELL_SIZE


func _two_drop() -> void:
	# remove the top pair of cells from the stack
	# ( x1 x2 - )
	_pop_dword()


func _two_dup() -> void:
	# duplicate the top cell pair
	# (x1 x2 - x1 x2 x1 x2 )
	var t: int = _get_dword(_ds_p)
	_push_dword(t)


func _two_over() -> void:
	# copy a cell pair x1 x2 to the top of the stack
	# ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
	_ds_p -= DS_DCELL_SIZE
	_set_dword(_ds_p, _get_dword(_ds_p + 2 * DS_DCELL_SIZE))


func _two_rot() -> void:
	# rotate the top three cell pairs on the stack
	# ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
	var t: int = _get_dword(_ds_p + 2 * DS_DCELL_SIZE)
	_set_dword(_ds_p + 2 * DS_DCELL_SIZE, _get_dword(_ds_p + DS_DCELL_SIZE))
	_set_dword(_ds_p + DS_DCELL_SIZE, _get_dword(_ds_p))
	_set_dword(_ds_p, t)


func _two_swap() -> void:
	# exchange the top two cell pairs
	# ( x1 x2 x3 x4 - x3 x4 x1 x2 )
	var t: int = _get_dword(_ds_p + DS_DCELL_SIZE)
	_set_dword(_ds_p + DS_DCELL_SIZE, _get_dword(_ds_p))
	_set_dword(_ds_p, t)

# Stack Operations
func _store() -> void:
	# Store x in the cell at a-addr
	# ( x a-addr - )
	var addr:int = _pop_word()
	_set_dword(addr, _pop_word())

func _fetch() -> void:
	# Replace a-addr with the contents of the cell at a_addr
	# ( a_addr - x )
	_push_word(_get_dword(_pop_word()))

# Execution Tokens
func _tick() -> void:
	# Search the dictionary for name and leave its execution token
	# on the stack. Abort if name cannot be found.
	# ( - xt )
	_push_word(TERM_BL.to_ascii_buffer()[0])
	_word()
	_count()
	var len: int = _pop_word()  # length
	var caddr: int = _pop_word()  # start
	var word:String = _str_from_addr_n(caddr, len)
	var token_addr = _find_in_dict(word)
	if not token_addr:
		_rprint_term(" " + word + " ?")
	else:
		_push_word(token_addr)
		_fetch()

func _execute() -> void:
	# Remove execution token xt from the stack and perform
	# the execution behavior it identifies
	# ( xt - )
	var xt:int = _pop_word()
	var f:Callable = _built_in_function_from_address.get(xt)
	if f:
		f.call()
	else:
		_rprint_term(" Invalid execution token")



# Programmer Conveniences
func _dot_s() -> void:
	var pointer = DS_TOP - DS_CELL_SIZE
	_rprint_term("")
	while pointer >= _ds_p:
		_print_term(" " + str(_get_int(pointer)))
		pointer -= DS_CELL_SIZE
	_print_term(" <-Top")


func _dot() -> void:
	_print_term(" " + str(_pop_int()))


func _d_dot() -> void:
	_print_term(" " + str(_pop_dint()))


func _star() -> void:
	# Multiply n1 by n2 leaving the product n3
	# ( n1 n2 - n3 )
	var t: int = _get_int(_ds_p) * _get_int(_ds_p + DS_CELL_SIZE)
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, t)


func _star_slash() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell quotient n4.
	# ( n1 n2 n3 - n4 )
	var p: int = (
		_get_int(_ds_p + DS_CELL_SIZE) * _get_int(_ds_p + DS_CELL_SIZE * 2)
	)
	var q: int = p / _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE * 2
	_set_int(_ds_p, q)


func _star_slash_mod() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell remainder n4
	# and a single-cell quotient n5
	# ( n1 n2 n3 - n4 n5 )
	var p: int = (
		_get_int(_ds_p + DS_CELL_SIZE) * _get_int(_ds_p + DS_CELL_SIZE * 2)
	)
	var r: int = p % _get_int(_ds_p)
	var q: int = p / _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, q)  # quotient
	_set_int(_ds_p + DS_CELL_SIZE, r)  # remainder


func _plus() -> void:
	# Add n1 to n2 leaving the sum n3
	# ( n1 n2 - n3 )
	var t: int = _get_int(_ds_p) + _get_int(_ds_p + DS_CELL_SIZE)
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, t)


func _minus() -> void:
	# subtract n2 from n1, leaving the diference n3
	# ( n1 n2 - n3 )
	var t: int = _get_int(_ds_p + DS_CELL_SIZE) - _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, t)


func _slash() -> void:
	# divide n1 by n2, leaving the quotient n3
	# ( n1 n2 - n3 )
	var t: int = _get_int(_ds_p + DS_CELL_SIZE) / _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, t)


func _slash_mod() -> void:
	# divide n1 by n2, leaving the remainder n3 and quotient n4
	# ( n1 n2 - n3 n4 )
	var q: int = _get_int(_ds_p + DS_CELL_SIZE) / _get_int(_ds_p)
	var r: int = _get_int(_ds_p + DS_CELL_SIZE) % _get_int(_ds_p)
	_set_int(_ds_p, q)
	_set_int(_ds_p + DS_CELL_SIZE, r)


func _one_plus() -> void:
	# Add one to n1, leaving n2
	# ( n1 - n2 )
	_set_int(_ds_p, _get_int(_ds_p) + 1)


func _one_minus() -> void:
	# Subtract one from n1, leaving n2
	# ( n1 - n2 )
	_set_int(_ds_p, _get_int(_ds_p) - 1)


func _two_plus() -> void:
	# Add two to n1, leaving n2
	# ( n1 - n2 )
	_set_int(_ds_p, _get_int(_ds_p) + 2)


func _two_minus() -> void:
	# Subtract two from n1, leaving n2
	# ( n1 - n2 )
	_set_int(_ds_p, _get_int(_ds_p) - 2)


func _two_star() -> void:
	# Return x2, result of shifting x1 one bit towards the MSB,
	# filling the LSB with zero
	# ( x1 - x2 )
	_set_int(_ds_p, _get_int(_ds_p) << 1)


func _two_slash() -> void:
	# Return x2, result of shifting x1 one bit towards LSB,
	# leaving the MSB unchanged
	# ( x1 - x2 )
	_set_int(_ds_p, _get_int(_ds_p) >> 1)


func _lshift() -> void:
	# Perform a logical left shift of u places on x1, giving x2._add_constant_central_force
	# Fill the vacated LSB bits with zero
	# (x1 u - x2 )
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, _get_int(_ds_p) << _get_int(_ds_p - DS_CELL_SIZE))


func _mod() -> void:
	# Divide n1 by n2, giving the remainder n3
	# (n1 n2 - n3 )
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, _get_int(_ds_p) % _get_int(_ds_p - DS_CELL_SIZE))


func _rshift() -> void:
	# Perform a logical right shift of u places on x1, giving x2.
	# Fill the vacated MSB bits with zeroes
	# ( x1 u - x2 )
	_ds_p += DS_CELL_SIZE
	_set_int(_ds_p, _get_word(_ds_p) >> _get_int(_ds_p - DS_CELL_SIZE))


func _d_plus() -> void:
	# Add d1 to d2, leaving the sum d3
	# ( d1 d2 - d3 )
	_ds_p += DS_DCELL_SIZE
	_set_dint(_ds_p, _get_dint(_ds_p) + _get_dint(_ds_p - DS_DCELL_SIZE))


func _d_minus() -> void:
	# Subtract d2 from d1, leaving the difference d3
	# ( d1 d2 - d3 )
	_ds_p += DS_DCELL_SIZE
	_set_dint(_ds_p, _get_dint(_ds_p) - _get_dint(_ds_p - DS_DCELL_SIZE))


func _d_two_star() -> void:
	# Multiply d1 by 2, leaving the result d2
	# ( d1 - d2 )
	_set_dint(_ds_p, _get_dint(_ds_p) * 2)


func _d_two_slash() -> void:
	# Divide d1 by 2, leaving the result d2
	# ( d1 - d2 )
	_set_dint(_ds_p, _get_dint(_ds_p) / 2)


func _d_to_s() -> void:
	# Convert double to single, discarding MS cell.
	# ( d - n )
	# this assumes doubles are pushed in LS MS order
	_pop_int()


func _m_star() -> void:
	# Multiply n1 by n2, leaving the double result d.
	# ( n1 n2 - d )
	_set_dint(_ds_p, _get_int(_ds_p) * _get_int(_ds_p + DS_CELL_SIZE))


func _m_star_slash() -> void:
	# Multiply d1 by n1 producing a triple cell intermediate result t.
	# Divide t by n2, giving quotient d2.
	# Use this with n1 or n2 = 1 to accomplish double precision multiplication
	# or division.
	# ( d1 n1 +n2 - d2 )
	# Following is an *approximate* implementation, using the double float
	var q: float = float(_get_int(_ds_p + DS_CELL_SIZE)) / _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE * 2
	_set_dint(_ds_p, _get_dint(_ds_p) * q)


func _m_plus() -> void:
	# Add n to d1 leaving the sum d2
	# ( d1 n - d2 )
	_ds_p += DS_CELL_SIZE
	_set_dint(_ds_p, _get_dint(_ds_p) + _get_int(_ds_p - DS_CELL_SIZE))


func _m_minus() -> void:
	# Subtract n from d1 leaving the difference d2
	# ( d1 n - d2 )
	_ds_p += DS_CELL_SIZE
	_set_dint(_ds_p, _get_dint(_ds_p) - _get_int(_ds_p - DS_CELL_SIZE))


func _m_slash() -> void:
	# Divide d by n1 leaving the single precision quotient n2
	# ( d n1 - n2 )
	var t: int = _get_dint(_ds_p + DS_CELL_SIZE) / _get_int(_ds_p)
	_ds_p += DS_DCELL_SIZE
	_set_int(_ds_p, t)


func _s_to_d() -> void:
	# Convert a single cell number n to its double equivalent d
	# ( n - d )
	var t: int = _get_int(_ds_p)
	_ds_p += DS_CELL_SIZE - DS_DCELL_SIZE
	_set_dint(_ds_p, t)


func _sm_slash_rem() -> void:
	# Divide d by n1, using symmetric division, giving quotient n3 and
	# remainder n2. All arguments are signed.
	# ( d n1 - n2 n3 )
	var dd: int = _get_dint(_ds_p + DS_CELL_SIZE)
	var d: int = _get_int(_ds_p)
	var q: int = dd / d
	var r: int = dd % d
	_ds_p += DS_DCELL_SIZE - DS_CELL_SIZE
	_set_int(_ds_p, q)
	_set_int(_ds_p + DS_CELL_SIZE, r)


func _um_slash_mod() -> void:
	# Divide ud by n1, leaving quotient n3 and remainder n2.
	# All arguments and result are unsigned.
	# ( d u1 - u2 u3 )
	var dd: int = _get_dword(_ds_p + DS_CELL_SIZE)
	var d: int = _get_word(_ds_p)
	var q: int = dd / d
	var r: int = dd % d
	_ds_p += DS_DCELL_SIZE - DS_CELL_SIZE
	_set_word(_ds_p, q)
	_set_word(_ds_p + DS_CELL_SIZE, r)


func _um_star() -> void:
	# Multiply u1 by u2, leaving the double-precision result ud
	# ( u1 u2 - ud )
	_set_dword(_ds_p, _get_word(_ds_p + DS_CELL_SIZE) * _get_word(_ds_p))


# Logical Operators
func _abs() -> void:
	# Replace the top stack item with its absolute value
	# ( n - +n )
	_set_word(_ds_p, abs(_get_int(_ds_p)))


func _and() -> void:
	# Return x3, the bit-wise logical and of x1 and x2
	# ( x1 x2 - x3)
	_ds_p += DS_CELL_SIZE
	_set_word(_ds_p, _get_word(_ds_p) & _get_word(_ds_p - DS_CELL_SIZE))


func _invert() -> void:
	# Invert all bits of x1, giving its logical inverse x2
	# ( x1 - x2 )
	_set_word(_ds_p, ~_get_word(_ds_p))


func _max() -> void:
	# Return n3, the greater of n1 and n2
	# ( n1 n2 - n3 )
	_ds_p += DS_CELL_SIZE
	var lt: bool = _get_int(_ds_p) < _get_int(_ds_p - DS_CELL_SIZE)
	if lt:
		_set_int(_ds_p, _get_int(_ds_p - DS_CELL_SIZE))


func _min() -> void:
	# Return n3, the lesser of n1 and n2
	# ( n1 n2 - n3 )
	_ds_p += DS_CELL_SIZE
	var gt: bool = _get_int(_ds_p) > _get_int(_ds_p - DS_CELL_SIZE)
	if gt:
		_set_int(_ds_p, _get_int(_ds_p - DS_CELL_SIZE))


func _negate() -> void:
	# Change the sign of the top stack value
	# ( n - -n )
	_set_int(_ds_p, -_get_int(_ds_p))


func _or() -> void:
	# Return x3, the bit-wise inclusive or of x1 with x2
	# ( x1 x2 - x3 )
	_ds_p += DS_CELL_SIZE
	_set_word(_ds_p, _get_word(_ds_p) | _get_word(_ds_p - DS_CELL_SIZE))


func _xor() -> void:
	# Return x3, the bit-wise exclusive or of x1 with x2
	# ( x1 x2 - x3 )
	_ds_p += DS_CELL_SIZE
	_set_word(_ds_p, _get_word(_ds_p) ^ _get_word(_ds_p - DS_CELL_SIZE))


# Double-Precision Logical Operators
func _d_abs() -> void:
	# Replace the top stack item with its absolute value
	# ( d - +d )
	_set_dword(_ds_p, abs(_get_dint(_ds_p)))


func _d_max() -> void:
	# Return d3, the greater of d1 and d2
	# ( d1 d2 - d3 )
	_ds_p += DS_DCELL_SIZE
	if _get_dint(_ds_p) < _get_dint(_ds_p - DS_DCELL_SIZE):
		_set_dint(_ds_p, _get_dint(_ds_p - DS_DCELL_SIZE))


func _d_min() -> void:
	# Return d3, the lesser of d1 and d2
	# ( d1 d2 - d3 )
	_ds_p += DS_DCELL_SIZE
	if _get_dint(_ds_p) > _get_dint(_ds_p - DS_DCELL_SIZE):
		_set_dint(_ds_p, _get_dint(_ds_p - DS_DCELL_SIZE))


func _d_negate() -> void:
	# Change the sign of the top stack value
	# ( d - -d )
	_set_dword(_ds_p, -_get_dint(_ds_p))


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
		var t: int = _get_byte(source_start + _get_word(ptraddr))
		if t == delim:
			# increment the input pointer
			_set_word(ptraddr, _get_word(ptraddr) + 1)
		else:
			break
	_parse()
	var count: int = _pop_word()
	var straddr: int = _pop_word()
	var ret: int = straddr - 1
	_set_byte(ret, count)
	_push_word(ret)


func _parse() -> void:
	# Parse text to the first instance of char, returning the address
	# and length of a temporary location containing the parsed text.
	# Returns an address with one byte available in front for forming
	# a character count.
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
		var t: int = _get_byte(source_start + _get_word(ptraddr))
		# a null character also stops the parse
		if t != 0 and t != delim:
			_set_byte(ptr, t)
			ptr += 1
			count += 1
			# increment the input pointer
			_set_word(ptraddr, _get_word(ptraddr) + 1)
		else:
			break
	_push_word(count)


func _b_l() -> void:
	# Return char, the ASCII character value of a space
	# ( - char )
	_push_word(int(TERM_BL))


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
	_push_word(_get_byte(addr))


func _compare() -> void:
	# Compare string to string (see details in docs)
	# ( c-addr1 u1 c-addr2 u2 - n )
	var n2: int = _pop_word()
	var a2: int = _pop_word()
	var n1: int = _pop_word()
	var a1: int = _pop_word()
	var s2: String = _str_from_addr_n(a2, n2)
	var s1: String = _str_from_addr_n(a1, n1)
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
	var a1: int = _get_word(_ds_p + 2 * DS_CELL_SIZE)
	var a2: int = _get_word(_ds_p + DS_CELL_SIZE)
	var u: int = _get_word(_ds_p)
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
		if u - i >= DS_DCELL_SIZE:
			_set_dword(a2 + i, _get_word(a1 + i))
			i += DS_DCELL_SIZE
		else:
			_set_byte(a2 + i, _get_byte(a1 + i))
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
		if i >= DS_DCELL_SIZE:
			i -= DS_DCELL_SIZE
			_set_dword(a2 + i, _get_word(a1 + i))
		else:
			i -= 1
			_set_byte(a2 + i, _get_byte(a1 + i))


# Dictionary

func _create() -> void:
	# Construct a dictionary entry for the next token in the input stream
	# Execution of *name* will return the address of its data space
	# ( - )
	# Grab the name
	_push_word(TERM_BL.to_ascii_buffer()[0])
	_word()
	_count()
	var len: int = _pop_word()  # length
	var caddr: int = _pop_word()  # start
	# poke address of last link at next spot
	_set_word(_dict_top, _dict_p)
	# move the top link 
	_dict_p = _dict_top
	_dict_top += DS_CELL_SIZE
	# poke the name length
	_set_byte(_dict_top, len)
	_dict_top += 1
	# copy the name
	_push_word(caddr)
	_push_word(_dict_top)
	_push_word(len)
	_move()
	_dict_top += len

	# create a closure for the return address
	var get_address = func():
		var data_space_addr:int = _dict_top + DS_CELL_SIZE
		return func():
			_push_word(data_space_addr)

	var execution_token:int = _allocate_execution_token(get_address.call())
	# copy the execution token
	_set_word(_dict_top, execution_token)
	_dict_top += DS_CELL_SIZE


func _allot() -> void:
	pass


func _unused() -> void:
	# Return u, the number of bytes remaining in the memory area
	# where dictionary entries are constructed.
	# ( - u )
	_push_word(DICT_TOP - _dict_top)

# gdlint:ignore = max-file-lines
