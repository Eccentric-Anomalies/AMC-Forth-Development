class_name ForthCommonUse
## Define built-in Forth words in common use.
##
## These words are not in the Forth Standard (forth-standard.org)
## but are in "common use" as described in "Forth Programmer's Handbook"
## by Conklin and Rather

extends ForthImplementationBase


## Initialize (executed automatically by ForthCommonUse.new())
##
## (1) Append an array of <WORD>, <function> pairs to the Forth
## list of built-in words (built_in_names).
## (2) Append an array of <function> references to the Forth
## list of built-in execution-time functions (if any)
func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				["2+", two_plus],  # common use
				["2-", two_minus],  # common use
				["M-", m_minus],  # common use
				["M/", m_slash],  # common use
			]
		)
	)
	forth.built_in_exec_functions.append_array([])


## 2+
func two_plus() -> void:
	# Add two to n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) + 2)


## 2-
func two_minus() -> void:
	# Subtract two from n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) - 2)


## M-
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


## M/
func m_slash() -> void:
	# Divide d by n1 leaving the single precision quotient n2
	# ( d n1 - n2 )
	var t: int = (
		forth.ram.get_dint(forth.ds_p + ForthRAM.CELL_SIZE)
		/ forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.DCELL_SIZE
	forth.ram.set_int(forth.ds_p, t)
