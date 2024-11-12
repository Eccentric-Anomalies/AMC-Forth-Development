class_name ForthToolsExt
## Define built-in Forth words in the TOOLS EXTENSION word set
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthToolsExt.new())
##
## (1) All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## (2) All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
## (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
func _init(_forth: AMCForth) -> void:
	super(_forth)


## WORD@ CS-PICK IMMEDIATE
func cs_pick() -> void:
	# Place copy of the uth CS entry on top of the CS stack
	# ( i*x u - i*x x_u )
	forth.cf_stack_pick(forth.pop_word())


## WORD@ CS-ROLL IMMEDIATE
func cs_roll() -> void:
	# Place copy of the uth CS entry on top of the CS stack
	# ( i*x u - i*x x_u )
	forth.cf_stack_roll(forth.pop_word())
