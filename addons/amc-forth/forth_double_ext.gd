class_name ForthDoubleExt
## Define built-in Forth words in the DOUBLE EXT word set
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthDoubleExt.new())
##
## (1) All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## (2) All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
## (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
func _init(_forth: AMCForth) -> void:
	super(_forth)


## @WORD 2ROT
func two_rot() -> void:
	# rotate the top three cell pairs on the stack
	# ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
	var t: int = forth.get_dint(4)
	forth.set_dint(4, forth.get_dint(2))
	forth.set_dint(2, forth.get_dint(0))
	forth.set_dint(0, t)
