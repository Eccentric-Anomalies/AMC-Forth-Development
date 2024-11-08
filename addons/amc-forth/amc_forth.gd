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
# Core Forth implementations
var core: ForthCore
var core_ext: ForthCoreExt
var tools: ForthTools
var common_use: ForthCommonUse
var double: ForthDouble
var double_ext: ForthDoubleExt
var string: ForthString

# The Forth data stack pointer is in byte units
var ds_p := DS_TOP

# The Forth dictionary space
var dict_p := DICT_START  # position of last link
var dict_top := DICT_START  # position of next new link to create
var dict_ip := 0  # code field pointer set to current execution point

# Built-In names have a run-time definition
# These are "<WORD>", <run-time function> pairs that are defined by each
# Forth implementation class (e.g. ForthDouble, etc.)
var built_in_names: Array = []
# list of built-in functions that have different
# compiled (execution token) behavior.
# These are <run-time function> items that are defined by each
# Forth implementation class (e.g. ForthDouble, etc.) when a
# different *compiled* behavior is required
var built_in_exec_functions: Array = []

# get "address" from built-in function
var address_from_built_in_function: Dictionary = {}
# get built-in function from "address"
var built_in_function_from_address: Dictionary = {}

# get built-in "address" from word
var _built_in_address: Dictionary = {}
# get built-in function from word
var _built_in_function: Dictionary = {}

# terminal scratchpad and buffer
var _terminal_pad: String = ""
var _pad_position := 0
var _parse_pointer := 0
var _terminal_buffer: Array = []
var _buffer_index := 0


func client_connected() -> void:
	terminal_out.emit(BANNER + ForthTerminal.CR + ForthTerminal.LF)


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


# Find word in dictionary, starting at address of top
# If found, returns the address of the first code field
# If not found, returns zero
func find_in_dict(word: String) -> int:
	if dict_p == dict_top:
		# dictionary is empty
		return 0
	# stuff the search string in data memory
	util.cstring_from_str(dict_top, word)
	# make a temporary pointer
	var p: int = dict_p
	while p != -1:
		push_word(dict_top)
		core.count()  # search word in addr, n format
		push_word(p + ForthRAM.CELL_SIZE)
		core.count()  # candidate word in addr, n format
		core.dup()  # copy the length
		var n_length: int = pop_word()
		string.compare()
		# is this the correct entry?
		if pop_word() == 0:
			# found it. Link address + link size + string length byte + string
			return p + ForthRAM.CELL_SIZE + 1 + n_length
		# not found, drill down to the next entry
		p = ram.get_int(p)
	# exhausted the dictionary, finding nothing
	return 0


func create_dict_entry_name() -> void:
	# Internal utility function for creating the start of
	# a dictionary entry. The next thing to follow will be
	# the execution token. Upon exit, dict_top will point to the
	# next byte in the entry.
	# ( - )
	# Grab the name
	push_word(ForthTerminal.BL.to_ascii_buffer()[0])
	core.word()
	core.count()
	var len: int = pop_word()  # length
	var caddr: int = pop_word()  # start
	# poke address of last link at next spot, but only if this isn't
	# the very first spot in the dictionary
	if dict_top != dict_p:
		ram.set_word(dict_top, dict_p)
	# move the top link
	dict_p = dict_top
	dict_top += ForthRAM.CELL_SIZE
	# poke the name length
	ram.set_byte(dict_top, len)
	dict_top += 1
	# copy the name
	push_word(caddr)
	push_word(dict_top)
	push_word(len)
	core.move()
	dict_top += len

# Forth Data Stack Push and Pop Routines

func push_int(val: int) -> void:
	ds_p -= ForthRAM.CELL_SIZE
	ram.set_int(ds_p, val)


func pop_int() -> int:
	var t: int = ram.get_int(ds_p)
	ds_p += ForthRAM.CELL_SIZE
	return t


func push_word(val: int) -> void:
	ds_p -= ForthRAM.CELL_SIZE
	ram.set_word(ds_p, val)


func pop_word() -> int:
	var t: int = ram.get_word(ds_p)
	ds_p += ForthRAM.CELL_SIZE
	return t


func push_dint(val: int) -> void:
	ds_p -= ForthRAM.DCELL_SIZE
	ram.set_dint(ds_p, val)


func pop_dint() -> int:
	var t: int = ram.get_dint(ds_p)
	ds_p += ForthRAM.DCELL_SIZE
	return t


func push_dword(val: int) -> void:
	ds_p -= ForthRAM.DCELL_SIZE
	ram.set_dword(ds_p, val)


func pop_dword() -> int:
	var t: int = ram.get_dword(ds_p)
	ds_p += ForthRAM.DCELL_SIZE
	return t


# privates

# Called when AMCForth.new() is executed
# This will cascade instantiation of all the Forth implementation classes
# and initialize dictionaries for relating built-in words and addresses
func _init() -> void:
	ram = ForthRAM.new(RAM_SIZE)
	util = ForthUtil.new(self)
	core = ForthCore.new(self)
	core_ext = ForthCoreExt.new(self)
	tools = ForthTools.new(self)
	common_use = ForthCommonUse.new(self)
	double = ForthDouble.new(self)
	double_ext = ForthDoubleExt.new(self)
	string = ForthString.new(self)
	_init_built_ins()
	# set the terminal link in the dictionary
	ram.set_int(dict_p, -1)
	# reset the buffer pointer
	ram.set_word(BUFF_TO_IN, 0)
	print(BANNER)


func _init_built_ins() -> void:
	var addr: int
	var token_count: int = DICT_VIRTUAL_START
	for i in ForthStdWords.STANDARD_NAMES.size():
		_built_in_address[ForthStdWords.STANDARD_NAMES[i]] = token_count
		token_count += ForthRAM.CELL_SIZE
	for i in built_in_names.size():
		var word: String = built_in_names[i][0]
		var f: Callable = built_in_names[i][1]
		# native functions are assigned virtual addresses, outside of
		# the real memory map.
		addr = _built_in_address[word]
		built_in_function_from_address[addr] = f
		address_from_built_in_function[f] = addr
		_built_in_function[word] = f
	# reset token count to point to the EXEC virtual addresses
	token_count = DICT_VIRTUAL_EXEC_START
	for f in built_in_exec_functions:
		built_in_function_from_address[token_count] = f
		address_from_built_in_function[f] = token_count
		token_count += ForthRAM.CELL_SIZE


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
		push_word(ForthTerminal.BL.to_ascii_buffer()[0])
		core.word()
		core.count()
		var len: int = pop_word()  # length of word
		var caddr: int = pop_word()  # start of word
		# out of tokens?
		if len == 0:
			# reset the buffer pointer
			_abort_line()
			break
		var t: String = util.str_from_addr_n(caddr, len)
		# t should be the next token
		var found_entry = find_in_dict(t)
		if found_entry != 0:
			push_word(found_entry)
			core.execute()
		elif t.to_upper() in _built_in_function:
			_built_in_function[t.to_upper()].call()
		# valid numeric value (double first)
		elif t.contains(".") and t.replace(".", "").is_valid_int():
			var t_strip: String = t.replace(".", "")
			var temp: int = t_strip.to_int()
			push_dword(temp)
		elif t.is_valid_int():
			var temp: int = t.to_int()
			# single-precision
			push_word(temp)
		# nothing we recognize
		else:
			util.print_unknown_word(t)
			_abort_line()
			return  # not ok
		# check the stack
		if ds_p < DS_START + DS_WORDS_GUARD:
			util.rprint_term(" Data stack overflow")
			ds_p = DS_START + DS_WORDS_GUARD
			_abort_line()
			return  # not ok
		if ds_p > DS_TOP:
			util.rprint_term(" Data stack underflow")
			ds_p = DS_TOP
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
