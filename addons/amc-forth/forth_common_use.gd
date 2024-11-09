class_name ForthCommonUse
## Define built-in Forth words in common use.
##
## These words are not in the Forth Standard (forth-standard.org)
## but are in "common use" as described in "Forth Programmer's Handbook"
## by Conklin and Rather

extends ForthImplementationBase


## Initialize (executed automatically by ForthCommonUse.new())
##
## All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
func _init(_forth: AMCForth) -> void:
	super(_forth)


## @WORD 2+
func two_plus() -> void:
	# Add two to n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) + 2)


## @WORD 2-
func two_minus() -> void:
	# Subtract two from n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) - 2)


## @WORD M-
func m_minus() -> void:
	# Subtract n from d1 leaving the difference d2
	# ( d1 n - d2 )
	forth.s_p += ForthRAM.CELL_SIZE
	forth.ram.set_dint(
		forth.ds_p,
		(
			forth.ram.get_dint(forth.ds_p)
			- forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)


## @WORD M/
func m_slash() -> void:
	# Divide d by n1 leaving the single precision quotient n2
	# ( d n1 - n2 )
	var t: int = (
		forth.ram.get_dint(forth.ds_p + ForthRAM.CELL_SIZE)
		/ forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.DCELL_SIZE
	forth.ram.set_int(forth.ds_p, t)
