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
	forth.data_stack[-1] += 2
	forth.data_stack[-1] &= ForthRAM.CELL_MASK


## @WORD 2-
func two_minus() -> void:
	# Subtract two from n1, leaving n2
	# ( n1 - n2 )
	forth.data_stack[-1] -= 2
	forth.data_stack[-1] &= ForthRAM.CELL_MASK


## @WORD M-
func m_minus() -> void:
	# Subtract n from d1 leaving the difference d2
	# ( d1 n - d2 )
	var n: int = forth.pop()
	forth.push_dint(forth.pop_dint() - n)


## @WORD M/
func m_slash() -> void:
	# Divide d by n1 leaving the single precision quotient n2
	# ( d n1 - n2 )
	var n: int = forth.pop()
	forth.push(forth.pop_dint() / n)
