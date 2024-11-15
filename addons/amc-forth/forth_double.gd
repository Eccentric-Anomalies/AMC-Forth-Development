class_name ForthDouble
## Define built-in Forth words in the DOUBLE word set
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthDouble.new())
##
## (1) All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## (2) All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
## (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
func _init(_forth: AMCForth) -> void:
	super(_forth)


## @WORD 2CONSTANT
func two_constant() -> void:
	# Create a dictionary entry for name, associated with constant double d.
	# ( d - )
	var init_val: int = forth.pop_dword()
	if forth.create_dict_entry_name():
		# copy the execution token
		forth.ram.set_word(
			forth.dict_top,
			forth.address_from_built_in_function[two_constant_exec]
		)
		# store the constant
		forth.ram.set_dword(forth.dict_top + ForthRAM.CELL_SIZE, init_val)
		forth.dict_top += ForthRAM.CELL_SIZE + ForthRAM.DCELL_SIZE
		# preserve dictionary state
		forth.save_dict_top()


## @WORDX 2CONSTANT
func two_constant_exec() -> void:
	# execution time functionality of _two_constant
	# return contents of double cell after execution token
	forth.push_dword(forth.ram.get_dword(forth.dict_ip + ForthRAM.CELL_SIZE))


## @WORD 2VARIABLE
func two_variable() -> void:
	# Create a ditionary entry for name associated with two cells of data
	# ( - )
	forth.core.create()
	# make room for one cell
	forth.dict_top += ForthRAM.DCELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORD D.
func d_dot() -> void:
	var fmt: String = "%d" if forth.ram.get_word(forth.BASE) == 10 else "%x"
	forth.util.print_term(" " + fmt % forth.pop_dint())


## @WORD D-
func d_minus() -> void:
	# Subtract d2 from d1, leaving the difference d3
	# ( d1 d2 - d3 )
	var t: int = forth.pop_dint()
	forth.push_dint(forth.pop_dint() - t)


## @WORD D+
func d_plus() -> void:
	# Add d1 to d2, leaving the sum d3
	# ( d1 d2 - d3 )
	forth.push_dint(forth.pop_dint() + forth.pop_dint())


## @WORD D2*
func d_two_star() -> void:
	# Multiply d1 by 2, leaving the result d2
	# ( d1 - d2 )
	forth.set_dint(0, forth.get_dint(0) * 2)


## @WORD D2/
func d_two_slash() -> void:
	# Divide d1 by 2, leaving the result d2
	# ( d1 - d2 )
	forth.set_dint(0, forth.get_dint(0) / 2)


## @WORD D>S
func d_to_s() -> void:
	# Convert double to single, discarding MS cell.
	# ( d - n )
	# this assumes doubles are pushed in LS MS order
	forth.pop()


## @WORD DABS
func d_abs() -> void:
	# Replace the top stack item with its absolute value
	# ( d - +d )
	forth.set_dint(0, abs(forth.get_dint(0)))


## @WORD DMAX
func d_max() -> void:
	# Return d3, the greater of d1 and d2
	# ( d1 d2 - d3 )
	var d2: int = forth.pop_dint()
	if d2 > forth.get_dint(0):
		forth.set_dint(0, d2)


## @WORD DMIN
func d_min() -> void:
	# Return d3, the lesser of d1 and d2
	# ( d1 d2 - d3 )
	var d2: int = forth.pop_dint()
	if d2 < forth.get_dint(0):
		forth.set_dint(0, d2)


## @WORD DNEGATE
func d_negate() -> void:
	# Change the sign of the top stack value
	# ( d - -d )
	forth.set_dint(0, -forth.get_dint(0))


## @WORD M*/
func m_star_slash() -> void:
	# Multiply d1 by n1 producing a triple cell intermediate result t.
	# Divide t by n2, giving quotient d2.
	# Use this with n1 or n2 = 1 to accomplish double precision multiplication
	# or division.
	# ( d1 n1 +n2 - d2 )
	# Following is an *approximate* implementation, using the double float
	var n2: int = forth.pop()
	var n1: int = forth.pop()
	var d1: int = forth.pop_dint()
	forth.push_dint(int((float(d1) / n2) * n1))


## @WORD M+
func m_plus() -> void:
	# Add n to d1 leaving the sum d2
	# ( d1 n - d2 )
	var n: int = forth.pop()
	forth.push_dint(forth.pop_dint() * n)
