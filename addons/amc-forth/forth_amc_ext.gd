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
	var port:int = forth.pop()
	forth.core.cells() # offset in bytes
	forth.push(AMCForth.IO_OUT_START)  # address of output block
	forth.core.plus() # output address
	forth.core.over() # copy value
	var value:int = forth.pop()
	forth.core.store()
	if port in forth.output_port_map:
		var sig:Signal = forth.output_port_map[port]
		call_deferred("output_emitter", port, value)

func output_emitter(port:int, value: int) -> void:
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
	# add a lookup entry for the port p, to execute <word>
	# ( p - )
	# usage: <port> LISTEN .  ( print port value when received )
	# convert port to address
	_get_port_address()
	forth.core.tick() 	# get the xt of the following word
	forth.core.swap()
	forth.core.store()

## @WORD UNLISTEN
func unlisten() -> void:
	# remove a lookup entry for the port p
	# ( p - )
	_get_port_address()
	forth.push(0)
	forth.core.swap()
	forth.core.store()
