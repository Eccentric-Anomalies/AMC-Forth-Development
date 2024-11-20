class_name ForthAMCExt
## Define built-in Forth words in the AMC EXT word set
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthAMCExt.new())
##
## (1) All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## (2) All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
## (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
func _init(_forth: AMCForth) -> void:
	super(_forth)


## @WORD OUT
func out() -> void:
	# save value x to I/O port p, possibly triggering Godot signal
	# ( x p - )
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
		call_deferred("output_emitter", port, value)


func output_emitter(port: int, value: int) -> void:
	forth.output_port_map[port].emit(value)


func _get_port_address() -> void:
	# Utility to accept port number and leave its address
	# in the handler table.
	# ( p - addr )
	forth.push(ForthRAM.CELL_SIZE)
	forth.core.star()
	forth.push(forth.IO_IN_MAP_START)
	forth.core.plus()


## @WORD LISTEN
func listen() -> void:
	# add a lookup entry for the IO port p, to execute <word>
	# ( p - )
	# usage: <port> LISTEN .  ( print port value when received )
	# convert port to address
	_get_port_address()
	forth.core.tick()  # get the xt of the following word
	forth.core.swap()
	forth.core.store()


## @WORD LOAD-SNAP
func load_snap() -> void:
	# Restore the Forth system RAM from backup file
	# ( - )
	forth.load_snapshot()


func _get_timer_address() -> void:
	# Utility to accept timer id and leave the start address of
	# its msec, xt pair
	# ( id - addr )
	forth.push(ForthRAM.CELL_SIZE)
	forth.core.two_star()
	forth.core.star()
	forth.push(forth.PERIODIC_START)
	forth.core.plus()


## @WORD P-TIMER
func p_timer() -> void:
	# start a periodic timer with id i, and interval n (msec) that
	# calls execution token given by <name>. Does nothing if the id
	# is in use.
	# ( i n - )  <name>
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
func p_stop() -> void:
	# stop a periodic timer with id i.
	# ( i - )
	_get_timer_address()  # ( i - addr )
	var addr = forth.pop()  # ( addr - )
	# clear the entries for the given timer id
	forth.ram.set_int(addr, 0)
	forth.ram.set_int(addr + ForthRAM.CELL_SIZE, 0)
	# the next time this timer expires, the system will find nothing
	# here for the ID, and it will be cancelled.


## @WORD POP-XY
func pop_x_y() -> void:
	# Configure output device so next character display will appear
	# at the column and row that were last saved with PUSH-XY
	# ( - )
	forth.util.print_term(ForthTerminal.ESC + "8")


## @WORD PUSH-XY
func push_x_y() -> void:
	# Tell the output device to save its current output position, to
	# be retrieved later using POP-XY
	# ( - )
	forth.util.print_term(ForthTerminal.ESC + "7")


## @WORD SAVE-SNAP
func save_snap() -> void:
	# Restore the Forth system RAM from backup file
	# ( - )
	forth.save_snapshot()


## @WORD UNLISTEN
func unlisten() -> void:
	# remove a lookup entry for the IO port p
	# ( p - )
	_get_port_address()
	forth.push(0)
	forth.core.swap()
	forth.core.store()
