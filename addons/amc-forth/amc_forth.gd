class_name AMCForth  # gdlint:ignore = max-public-methods

extends RefCounted

signal terminal_out(text: String)
signal terminal_in_ready

const BANNER := "AMC Forth"

# Memory Map
const RAM_SIZE := 0x10000  # BYTES
# Dictionary
const DICT_START := 0x0100  # BYTES
const DICT_SIZE := 0x08000
const DICT_TOP := DICT_START + DICT_SIZE
# Input Buffer
const BUFF_SOURCE_SIZE := 0x0100  # bytes
const BUFF_SOURCE_START := DICT_TOP
const BUFF_SOURCE_TOP := BUFF_SOURCE_START + BUFF_SOURCE_SIZE
# Pointer to the parse position in the buffer
const BUFF_TO_IN := BUFF_SOURCE_TOP
const BUFF_TO_IN_TOP := BUFF_TO_IN + ForthRAM.CELL_SIZE
# Temporary word storage (used by WORD)
const WORD_SIZE := 0x0100
const WORD_START := BUFF_TO_IN_TOP
const WORD_TOP := WORD_START + WORD_SIZE
# BASE cell
const BASE := WORD_TOP
# DICT_TOP_PTR cell
const DICT_TOP_PTR := BASE + ForthRAM.CELL_SIZE
# DICT_PTR
const DICT_PTR := DICT_TOP_PTR + ForthRAM.CELL_SIZE

# IO SPACE - cell-sized ports identified by port # ranging from 0 to 255
const IO_OUT_PORT_QTY := 0x0100
const IO_OUT_TOP:= RAM_SIZE
const IO_OUT_START:= IO_OUT_TOP - IO_OUT_PORT_QTY * ForthRAM.CELL_SIZE
const IO_IN_PORT_QTY := 0x0100
const IO_IN_TOP := IO_OUT_START
const IO_IN_START := IO_IN_TOP - IO_IN_PORT_QTY * ForthRAM.CELL_SIZE
const IO_IN_MAP_TOP := IO_IN_START
# xt for every port that is being listened on
const IO_IN_MAP_START := IO_IN_MAP_TOP - IO_IN_PORT_QTY * ForthRAM.CELL_SIZE
# PERIODIC TIMER SPACE
const PERIODIC_TIMER_QTY := 0x080	# Timer IDs 0-127, stored as @addr: msec, xt
const PERIODIC_TOP := IO_IN_START
const PERIODIC_START := PERIODIC_TOP - PERIODIC_TIMER_QTY * ForthRAM.CELL_SIZE * 2

# Add more pointers here

const TRUE := int(-1)
const FALSE := int(0)

const MAX_BUFFER_SIZE := 20

const DATA_STACK_SIZE := 100
const DATA_STACK_TOP := DATA_STACK_SIZE - 1

# Masks for built-in execution tokens
const BUILT_IN_XT_MASK = 0x080 * 0x100 ** (ForthRAM.CELL_SIZE - 1)
const BUILT_IN_XTX_MASK = 0x040 * 0x100 ** (ForthRAM.CELL_SIZE - 1)
# Ensure we don't generate tokens that are larger than the CELL_SIZE
const BUILT_IN_MASK = (
	~(BUILT_IN_XT_MASK | BUILT_IN_XTX_MASK) & (0x100 ** ForthRAM.CELL_SIZE - 1)
)

# Smudge bit mask
const SMUDGE_BIT_MASK = 0x80
# Immediate bit mask
const IMMEDIATE_BIT_MASK = 0x40
# Largest name length
const MAX_NAME_LENGTH = 0x3f

# Reference to the physical memory and utilities
var ram: ForthRAM
var util: ForthUtil
# Core Forth word implementations
var core: ForthCore
var core_ext: ForthCoreExt
var tools: ForthTools
var tools_ext: ForthToolsExt
var common_use: ForthCommonUse
var double: ForthDouble
var double_ext: ForthDoubleExt
var string: ForthString
var amc_ext: ForthAMCExt
var facility: ForthFacility

# The Forth data stack pointer is in byte units

# The Forth dictionary space
var dict_p: int  # position of last link  FIXME
var dict_top: int  # position of next new link to create
var dict_ip := 0  # code field pointer set to current execution point

# Forth compile state
var state: bool = false

# Forth source ID
var source_id: int = 0  # 0 default, -1 ram buffer
var source_id_stack: Array = []

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
# List of built-in names that are IMMEDIATE by default
var immediate_names: Array = []

# get "address" from built-in function
var address_from_built_in_function: Dictionary = {}
# get built-in function from "address"
var built_in_function_from_address: Dictionary = {}
# get built-in function from word
var built_in_function: Dictionary = {}


# Forth : exit flag (true if exit has been called)
var exit_flag: bool = false

# Forth: data stack
var data_stack: PackedInt64Array
var ds_p: int

# Output handlers
var output_port_map:Dictionary = {}
# Input event list
var input_port_events:Array = []
# Periodic timer list
var periodic_timer_map:Dictionary = {}
# Timer events queue
var timer_events:Array = []

# Owning Node
var _node

var _data_stack_underflow: bool = false

# terminal scratchpad and buffer
var _terminal_pad: String = ""
var _pad_position := 0
var _parse_pointer := 0
var _terminal_buffer: Array = []
var _buffer_index := 0

# Forth : execution dict_ip stack
var _dict_ip_stack: Array = []

# Forth: control flow stack
var _control_flow_stack: Array = []

# Thread data
var _thread: Thread
var _input_ready: Semaphore
var _output_done: bool

func client_connected() -> void:
	terminal_out.emit(BANNER + ForthTerminal.CR + ForthTerminal.LF)


# pause until Forth is ready to accept inupt
func is_ready_for_input() -> bool:
	return _output_done


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
			# refresh the line in the terminal
			_pad_position = _terminal_pad.length()
			terminal_out.emit(_refresh_edit_text())
			echo_text = ""
			# text is ready for the Forth interpreter
			_input_ready.post()
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
# Returns a list consisting of:
#  > the address of the first code field (zero if not found)
#  > a boolean true if the word is defined as IMMEDIATE
func find_in_dict(word: String) -> Array:
	if dict_p == dict_top:
		# dictionary is empty
		return [0, false]
	# stuff the search string in data memory
	util.cstring_from_str(dict_top, word)
	# make a temporary pointer
	var p: int = dict_p
	while p != -1:  # <empty>
		push(dict_top)  # c-addr
		core.count()  # search word in addr  # addr n
		push(p + ForthRAM.CELL_SIZE)  # entry name  # addr n c-addr
		core.count()  # candidate word in addr			# addr n addr n
		var n_raw_length: int = pop()  # addr n addr
		var n_length: int = (
			n_raw_length & ~(SMUDGE_BIT_MASK | IMMEDIATE_BIT_MASK)
		)
		push(n_length)  # strip the SMUDGE and IMMEDIATE bits and restore # addr n addr n
		# only check if the entry has a clear smudge bit
		if not (n_raw_length & SMUDGE_BIT_MASK):
			string.compare()  # n
			# is this the correct entry?
			if pop() == 0:  #
				# found it. Link address + link size + string length byte + string, aligned
				push(p + ForthRAM.CELL_SIZE + 1 + n_length)  # n
				core.aligned()  # a
				return [pop(), (n_raw_length & IMMEDIATE_BIT_MASK) != 0]  #
		else:
			# clean up the stack
			pop_dword()  # addr n
			pop_dword()  #
		# not found, drill down to the next entry
		p = ram.get_int(p)
	# exhausted the dictionary, finding nothing
	return [0, false]


func create_dict_entry_name(smudge: bool = false) -> int:
	# Internal utility function for creating the start of
	# a dictionary entry. The next thing to follow will be
	# the execution token. Upon exit, dict_top will point to the
	# aligned position of the execution token to be.
	# Accepts an optional smudge state (default false).
	# Returns the address of the name length byte or zero on fail.
	# ( - )
	# Grab the name
	push(ForthTerminal.BL.to_ascii_buffer()[0])
	core.word()
	core.count()
	var len: int = pop()  # length
	var caddr: int = pop()  # start
	if len <= MAX_NAME_LENGTH:
		# poke address of last link at next spot, but only if this isn't
		# the very first spot in the dictionary
		if dict_top != dict_p:
			ram.set_word(dict_top, dict_p)
		# align the top pointer, so link will be word-aligned
		core.align()
		# move the top link
		dict_p = dict_top
		save_dict_p()
		dict_top += ForthRAM.CELL_SIZE
		# poke the name length, with a smudge bit if needed
		var smudge_bit: int = SMUDGE_BIT_MASK if smudge else 0
		ram.set_byte(dict_top, len | smudge_bit)
		# preserve the address of the length byte
		var ret: int = dict_top
		dict_top += 1
		# copy the name
		push(caddr)
		push(dict_top)
		push(len)
		core.move()
		dict_top += len
		core.align()  # will save dict_top
		# the address of the name length byte
		return ret
	return 0

# Forth Input and Output Interface

# Register an output signal handler (port triggers message out)
# Message will fire with Forth OUT ( x p - )
func add_output_signal(port:int, s:Signal) -> void:
	output_port_map[port] = s


# Register an input signal handler (message in triggers input action)
# Register a handler function with Forth LISTEN ( p xt - )
func add_input_signal(port:int, s:Signal) -> void:

	var signal_receiver = func(value:int) -> void: _insert_new_event(port, value)

	s.connect(signal_receiver)


# Utility function to add an input event to the queue
func _insert_new_event(port: int, value:int) -> void:
	var item = [port, value]
	if not item in input_port_events:
		input_port_events.push_front(item)
		# bump the semaphore count
		_input_ready.post()


# Start a periodic timer with id to call an execution token
# This is only called from within Forth code!
func start_periodic_timer(id:int, msec:int, xt:int) -> void:

	var signal_receiver = func() -> void: _handle_timeout(id)

	# save info
	var timer:= Timer.new()
	periodic_timer_map[id] = [msec, xt, timer]
	timer.wait_time = msec / 1000.0
	timer.autostart = true
	timer.connect("timeout", signal_receiver)
	_node.call_deferred("add_child", timer)

# Utility function to service periodic timer expirations
func _handle_timeout(id:int) -> void:
	if not id in timer_events:	# don't allow timer events to stack..
		timer_events.push_front(id)
		# bump the semaphore count
		_input_ready.post()

# Stop a timer
func _remove_timer(id:int) -> void:
	if id in periodic_timer_map:
		var timer:Timer = periodic_timer_map[id][2]
		timer.stop()
		_node.remove_child(timer)

# Forth Data Stack Push and Pop Routines

func push(val: int) -> void:
	ds_p -= 1
	data_stack[ds_p] = val


func pop() -> int:
	if ds_p < DATA_STACK_SIZE:
		ds_p += 1
		return data_stack[ds_p - 1]
	util.rprint_term(" Data stack underflow")
	return 0


func push_dint(val: int) -> void:
	var t: Array = ram.split_64(val)
	push(t[1])
	push(t[0])


func pop_dint() -> int:
	return ram.combine_64(pop(), pop())


# top of stack is 0, next dint is at 2, etc.
func get_dint(index: int) -> int:
	return ram.combine_64(
		data_stack[ds_p + index], data_stack[ds_p + index + 1]
	)


func set_dint(index: int, value: int) -> void:
	var s: Array = ram.split_64(value)
	data_stack[ds_p + index] = s[0]
	data_stack[ds_p + index + 1] = s[1]


func push_dword(value: int) -> void:
	var s: Array = ram.split_64(value)
	push(s[1])
	push(s[0])


func set_dword(index: int, value: int) -> void:
	var s: Array = ram.split_64(value)
	data_stack[ds_p + index] = s[0]
	data_stack[ds_p + index + 1] = s[1]


func pop_dword() -> int:
	return ram.combine_64(pop(), pop())


# top of stack is -1, next dint is at -3, etc.
func get_dword(index: int) -> int:
	return ram.combine_64(
		data_stack[ds_p + index], data_stack[ds_p + index + 1]
	)


# save the internal top of dict pointer to RAM
func save_dict_top() -> void:
	ram.set_word(DICT_TOP_PTR, dict_top)


# save the internal dict pointer to RAM
func save_dict_p() -> void:
	ram.set_word(DICT_PTR, dict_p)


# retrieve the internal top of dict pointer from RAM
func restore_dict_top() -> void:
	dict_top = ram.get_word(DICT_TOP_PTR)


# retrieve the internal dict pointer from RAM
func restore_dict_p() -> void:
	dict_p = ram.get_word(DICT_PTR)


# dictionary instruction pointer manipulation
# push the current dict_ip
func push_ip() -> void:
	_dict_ip_stack.push_back(dict_ip)


func pop_ip() -> void:
	dict_ip = _dict_ip_stack.pop_back()


func ip_stack_is_empty() -> bool:
	return _dict_ip_stack.size() == 0


# compiled word control flow stack
# push a word
func cf_push(addr: int) -> void:
	_control_flow_stack.push_front(addr)


# pop a word
func cf_pop() -> int:
	if not cf_stack_is_empty():
		return _control_flow_stack.pop_front()
	util.rprint_term("Unbalanced control structure")
	return 0


# control flow stack is empty
func cf_stack_is_empty() -> bool:
	return _control_flow_stack.size() == 0


# control flow stack PICK (implements CS-PICK)
func cf_stack_pick(item: int) -> void:
	cf_push(_control_flow_stack[item])


# control flow stack ROLL (implements CS-ROLL)
func cf_stack_roll(item: int) -> void:
	cf_push(_control_flow_stack.pop_at(item))


# PRIVATES


# Called when AMCForth.new() is executed
# This will cascade instantiation of all the Forth implementation classes
# and initialize dictionaries for relating built-in words and addresses
func _init(node:Node) -> void:
	# save the instantiating node
	_node = node
	# the top of the dictionary can't overlap the high-memory stuff
	assert(DICT_TOP < PERIODIC_START)
	ram = ForthRAM.new(RAM_SIZE)
	util = ForthUtil.new(self)
	# Instantiate Forth word definitions
	core = ForthCore.new(self)
	core_ext = ForthCoreExt.new(self)
	tools = ForthTools.new(self)
	tools_ext = ForthToolsExt.new(self)
	common_use = ForthCommonUse.new(self)
	double = ForthDouble.new(self)
	double_ext = ForthDoubleExt.new(self)
	string = ForthString.new(self)
	amc_ext = ForthAMCExt.new(self)
	facility = ForthFacility.new(self)
	# End Forth word definitions
	_init_built_ins()
	# Initialize the data stack
	data_stack.resize(DATA_STACK_SIZE)
	data_stack.fill(0)
	ds_p = DATA_STACK_SIZE  # empty
	# set the terminal link in the dictionary
	ram.set_int(dict_p, -1)
	# reset the buffer pointer
	ram.set_word(BUFF_TO_IN, 0)
	# set the base
	core.decimal()
	# initialize dictionary pointers and save them to RAM
	# FIXME note these have to be initialized when re-loading state
	dict_p = DICT_START  # position of last link
	save_dict_p()
	dict_top = DICT_START  # position of next new link to create
	save_dict_top()
	# Launch the AMC Forth thread
	_thread = Thread.new()
	# feed a test loop into the dictionary
	_terminal_pad = ": LOOPN BEGIN 1- DUP IF FALSE ELSE TRUE THEN UNTIL DROP ;"
	_interpret_terminal_line()
	# end test
	_input_ready = Semaphore.new()
	_thread.start(_input_thread, Thread.PRIORITY_LOW)
	_output_done = true
	print(BANNER)


func _input_thread() -> void:
	while true:
		_input_ready.wait()
		# preferentially handle input port signals
		if input_port_events.size():
			var evt = input_port_events.pop_back()
			# only execute if Forth is listening on this port
			var xt:int = ram.get_word(IO_IN_MAP_START + evt[0]*ForthRAM.CELL_SIZE)
			if xt:
				push(evt[1])  # store the value
				push(xt) # push the xt
				core.execute()
		# followed by timer timeouts
		elif timer_events.size():
			var id = timer_events.pop_back()
			# only execute if Forth is still listening on this id
			var xt:int = ram.get_word(PERIODIC_START + (id*2 + 1)*ForthRAM.CELL_SIZE)
			if xt:
				push(xt)
				core.execute()
			else: # not listening any longer. remove the timer.
				call_deferred("_remove_timer", id)
		else:
			# no input events, must be terminal input line
			_output_done = false
			_interpret_terminal_line()
			_output_done = true


# generate execution tokens by hashing Forth Word
func xt_from_word(word: String) -> int:
	return BUILT_IN_XT_MASK + (BUILT_IN_MASK & word.hash())


# generate run-time execution tokens by hashing Forth Word
func _xtx_from_word(word: String) -> int:
	return BUILT_IN_XTX_MASK + (BUILT_IN_MASK & word.hash())


func _init_built_ins() -> void:
	var addr: int
	for i in built_in_names.size():
		var word: String = built_in_names[i][0]
		var f: Callable = built_in_names[i][1]
		# native functions are assigned virtual addresses, outside of
		# the real memory map.
		addr = xt_from_word(word)
		assert(
			not built_in_function_from_address.has(addr),
			"Duplicate Forth word hash must be resolved."
		)
		built_in_function_from_address[addr] = f
		address_from_built_in_function[f] = addr
		built_in_function[word] = f
	for i in built_in_exec_functions.size():
		var word: String = built_in_exec_functions[i][0]
		var f: Callable = built_in_exec_functions[i][1]
		addr = _xtx_from_word(word)
		built_in_function_from_address[addr] = f
		address_from_built_in_function[f] = addr


func reset_buff_to_in() -> void:
	ram.set_word(BUFF_TO_IN, 0)


func is_valid_int(word: String, base: int = 10) -> bool:
	if base == 16:
		return word.is_valid_hex_number()
	return word.is_valid_int()


func to_int(word: String, base: int = 10) -> int:
	if base == 16:
		return word.hex_to_int()
	return word.to_int()


# Given a word, determine if it is immediate or not.
func is_immediate(word: String) -> bool:
	return word in immediate_names


# Interpret the _terminal_pad content
func _interpret_terminal_line() -> void:
	var bytes_input: PackedByteArray = _terminal_pad.to_ascii_buffer()
	_terminal_pad = ""
	_pad_position = 0
	bytes_input.push_back(0)  # null terminate
	# transfer to the RAM-based input buffer (accessible to the engine)
	for i in bytes_input.size():
		ram.set_byte(BUFF_SOURCE_START + i, bytes_input[i])
	core.evaluate()
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
