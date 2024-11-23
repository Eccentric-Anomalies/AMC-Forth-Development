class_name ForthAMCExt
## @WORDSET AMC Extended
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthAMCExt.new())
##
## (1) All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## (2) All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
## (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
## (4) UP TO four comments beginning with "##" before function
## (5) Final comment must be "## @STACK" followed by stack def.
func _init(_forth: AMCForth) -> void:
	super(_forth)


## @WORD BLINKV
## Send BLINK command to terminal.
## @STACK ( - )
func blink_v() -> void:
	forth.util.print_term(ForthTerminal.BLINK)


## @WORD BOLDV
## Send BOLD command to terminal.
## @STACK ( - )
func bold_v() -> void:
	forth.util.print_term(ForthTerminal.BOLD)


func _get_port_address() -> void:
	# Utility to accept port number and leave its address
	# in the handler table.
	# ( p - addr )
	forth.push(ForthRAM.CELL_SIZE)
	forth.core.star()
	forth.push(forth.IO_IN_MAP_START)
	forth.core.plus()

# helper function for retrieving the next word
func _next_word() -> String:
	# retrieve the name token
	forth.push(ForthTerminal.BL.to_ascii_buffer()[0])
	forth.core.word()
	forth.core.count()
	var len: int = forth.pop()  # length
	var caddr: int = forth.pop()  # start
	return forth.util.str_from_addr_n(caddr, len)


## @WORD HELP
## Display the description for the following Forth built-in word.
## @STACK ( "name" - )
func help() -> void:
	forth.util.print_term(" " + forth.word_description.get(_next_word(),"(not found)"))


## @WORD HELPS
## Display stack definition for the following Forth word.
## @STACK ( "name" - )
func help_s() -> void:
	forth.util.print_term(" " + forth.word_stackdef.get(_next_word(),"(not found)"))

## @WORD HELPWS
## Display word set for the following Forth word.
## @STACK ( "name" - )
func help_w_s() -> void:
	forth.util.print_term(" " + forth.word_wordset.get(_next_word(),"(not found)"))


## @WORD INVISIBLEV
## Send INVISIBLE command to terminal.
## @STACK ( - )
func invisible_v() -> void:
	forth.util.print_term(ForthTerminal.INVISIBLE)


## @WORD LISTEN
## Add a lookup entry for the IO port p, to execute <word>.
## Usage: <port> LISTEN . ( prints port value when received )
## @STACK ( "word" p - )
func listen() -> void:
	# convert port to address
	_get_port_address()
	forth.core.tick()  # get the xt of the following word
	forth.core.swap()
	forth.core.store()


## @WORD LOAD-SNAP
## Restore the Forth system RAM from backup file.
## @STACK ( - )
func load_snap() -> void:
	forth.load_snapshot()


## @WORD LOWV
## Send LOWINT (low intensity) command to terminal.
## @STACK ( - )
func low_v() -> void:
	forth.util.print_term(ForthTerminal.LOWINT)


func _get_timer_address() -> void:
	# Utility to accept timer id and leave the start address of
	# its msec, xt pair
	# ( id - addr )
	forth.push(ForthRAM.CELL_SIZE)
	forth.core.two_star()
	forth.core.star()
	forth.push(forth.PERIODIC_START)
	forth.core.plus()


## @WORD NOMODEV
## Send MODESOFF command to terminal.
## @STACK ( - )
func nomode_v() -> void:
	forth.util.print_term(ForthTerminal.MODESOFF)


## @WORD OUT
## Save value x to I/O port p, possibly triggering Godot signal.
## @STACK ( x p - )
func out() -> void:
	forth.core.dup()
	var port: int = forth.pop()
	forth.core.cells()  # offset in bytes
	forth.push(AMCForth.IO_OUT_START)  # address of output block
	forth.core.plus()  # output address
	forth.core.over()  # copy value
	var value: int = forth.pop()
	forth.core.store()
	if port in forth.output_port_map:
		var sig: Signal = forth.output_port_map[port]
		call_deferred("_output_emitter", port, value)


func _output_emitter(port: int, value: int) -> void:
	forth.output_port_map[port].emit(value)


## @WORD P-TIMER
## Start a periodic timer with id i, and interval n (msec) that
## calls execution token given by <name>. Does nothing if the id
## is in use. Usage: <id> <msec> P-TIMER <name>
## @STACK ( "name" i n - )
func p_timer() -> void:
	forth.core.swap()  # ( i n - n i )
	forth.core.dup()  # ( n i - n i i )
	var id: int = forth.pop()  # ( n i i - n i )
	_get_timer_address()  # ( n i - n addr )
	forth.core.tick()  # ( n addr - n addr xt )
	var xt: int = forth.pop()
	var addr: int = forth.pop()
	var ms: int = forth.pop()  # ( - )
	if ms and not forth.ram.get_int(addr):  # only if non-zero and nothing already there
		forth.ram.set_int(addr, ms)
		forth.ram.set_int(addr + ForthRAM.CELL_SIZE, xt)
		forth.start_periodic_timer(id, ms, xt)


## @WORD P-STOP
## Stop periodic timer with id i.
## @ STACK ( i - )
func p_stop() -> void:
	_get_timer_address()  # ( i - addr )
	var addr = forth.pop()  # ( addr - )
	# clear the entries for the given timer id
	forth.ram.set_int(addr, 0)
	forth.ram.set_int(addr + ForthRAM.CELL_SIZE, 0)
	# the next time this timer expires, the system will find nothing
	# here for the ID, and it will be cancelled.


## @WORD POP-XY
## Configure output device so next character display will appear
## at the column and row that were last saved with PUSH-XY.
## @STACK ( - )
func pop_x_y() -> void:
	forth.util.print_term(ForthTerminal.ESC + "8")


## @WORD PUSH-XY
## Tell the output device to save its current output position, to
## be retrieved later using POP-XY.
## @STACK ( - )
func push_x_y() -> void:
	forth.util.print_term(ForthTerminal.ESC + "7")


## @WORD REVERSEV
## Send REVERSE command to terminal.
## @STACK ( - )
func reverse_v() -> void:
	forth.util.print_term(ForthTerminal.REVERSE)


## @WORD SAVE-SNAP
## Restore the Forth system RAM from backup file.
## @STACK ( - )
func save_snap() -> void:
	forth.save_snapshot()


## @WORD UNDERLINEV
## Send UNDERLINE command to terminal.
## @STACK ( - )
func underline_v() -> void:
	forth.util.print_term(ForthTerminal.UNDERLINE)


## @WORD UNLISTEN
## Remove a lookup entry for the IO port p.
## @STACK ( p - )
func unlisten() -> void:
	_get_port_address()
	forth.push(0)
	forth.core.swap()
	forth.core.store()
