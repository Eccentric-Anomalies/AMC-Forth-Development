class_name ForthToolsExt
## @WORDSET Tools Extended
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthToolsExt.new())
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


## @WORD AHEAD IMMEDIATE
## Place forward reference origin on the control flow stack.
## @STACK ( - orig )
func ahead() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[ahead_exec]
	)
	# leave link address on the control stack
	forth.cf_push_orig(forth.dict_top + ForthRAM.CELL_SIZE)
	# move up to finish
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX AHEAD
func ahead_exec() -> void:
	# Branch to ELSE if top of stack not TRUE.
	# ( x - )
	# Skip ahead to the address in the next cell
	forth.dict_ip = forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE)


## WORD@ CS-PICK IMMEDIATE
## Place copy of the uth CS entry on top of the CS stack.
## @STACK ( i*x u - i*x x_u )
func cs_pick() -> void:
	forth.cf_stack_pick(forth.pop())


## WORD@ CS-ROLL IMMEDIATE
## Move the uth CS entry on top of the CS stack.
## @STACK ( i*x u - i*x x_u )
func cs_roll() -> void:
	forth.cf_stack_roll(forth.pop())
