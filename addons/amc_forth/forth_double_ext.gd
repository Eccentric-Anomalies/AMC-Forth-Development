class_name ForthDoubleExt
## @WORDSET Double Extended
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthDoubleExt.new())
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


## @WORD 2ROT
## Rotate the top three cell pairs on the stack.
## @STACK ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
func two_rot() -> void:
	var t: int = forth.get_dint(4)
	forth.set_dint(4, forth.get_dint(2))
	forth.set_dint(2, forth.get_dint(0))
	forth.set_dint(0, t)
