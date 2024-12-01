class_name ForthCommonUse
## @WORDSET Common Use
##
## These words are not in the Forth Standard (forth-standard.org)
## but are in "common use" as described in "Forth Programmer's Handbook"
## by Conklin and Rather

extends ForthImplementationBase


## Initialize (executed automatically by ForthCommonUse.new())
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


## @WORD 2+
## Add two to n1, leaving n2.
## @STACK ( n1 - n2 )
func two_plus() -> void:
	forth.push(2)
	forth.core.plus()


## @WORD 2-
## Subtract two from n1, leaving n2.
## @STACK ( n1 - n2 )
func two_minus() -> void:
	forth.push(2)
	forth.core.minus()


## @WORD M-
## Subtract n from d1 leaving the difference d2.
## @STACK ( d1 n - d2 )
func m_minus() -> void:
	var n: int = forth.pop()
	forth.push_dint(forth.pop_dint() - n)


## @WORD M/
## Divide d by n1 leaving the single precision quotient n2.
## @STACK ( d n1 - n2 )
func m_slash() -> void:
	var n: int = forth.pop()
	forth.push(forth.pop_dint() / n)


## @WORD NOT
## Identical to 0=, used for program clarity to reverse logical result.
## @STACK ( x - flag )
func f_not() -> void:
	forth.core.zero_equal()
