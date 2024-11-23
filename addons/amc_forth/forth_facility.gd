class_name ForthFacility
## @WORDSET Facility
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthFacility.new())
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


## @WORD AT-XY
## Configure output device so next character display will appear
## at column u1, row u2 of the output area (origin in upper left).
## @STACK ( u1 u2 - )
func at_x_y() -> void:
	var u2: int = forth.pop()
	var u1: int = forth.pop()
	forth.util.print_term(ForthTerminal.ESC + "[%d;%dH" % [u1, u2])


## @WORD PAGE
## On a CRT, clear the screen and reset cursor position to the upper left
## corner.
## @STACK ( - )
func page() -> void:
	forth.util.print_term(ForthTerminal.CLRSCR)
	forth.push(1)
	forth.core.dup()
	at_x_y()
