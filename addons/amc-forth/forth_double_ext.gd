class_name ForthDoubleExt
## Define built-in Forth words in the DOUBLE EXT word set
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthDoubleExt.new())
##
## All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
func _init(_forth: AMCForth) -> void:
	super(_forth)


## @WORD
func two_rot() -> void:
	# rotate the top three cell pairs on the stack
	# ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
	var t: int = forth.ram.get_dword(forth.ds_p + 2 * ForthRAM.DCELL_SIZE)
	forth.ram.set_dword(
		forth.ds_p + 2 * ForthRAM.DCELL_SIZE,
		forth.ram.get_dword(forth.ds_p + ForthRAM.DCELL_SIZE)
	)
	forth.ram.set_dword(
		forth.ds_p + ForthRAM.DCELL_SIZE, forth.ram.get_dword(forth.ds_p)
	)
	forth.ram.set_dword(forth.ds_p, t)
