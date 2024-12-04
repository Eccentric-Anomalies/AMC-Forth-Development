class_name ForthDouble  # gdlint:ignore = max-public-methods
## @WORDSET Double
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthDouble.new())
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


## @WORD 2CONSTANT
## Create a dictionary entry for name, associated with constant double d.
## @STACK Compile: ( "name" d - ), Execute: ( - d )
func two_constant() -> void:
	var init_val: int = forth.pop_dword()
	if forth.create_dict_entry_name():
		# copy the execution token
		forth.ram.set_int(
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


## @WORD 2LITERAL
## At compile time, remove the top two numbers from the stack and compile
## into the current definition.
## @STACK Compile:  ( x x - ), Execute: ( - x x )
func two_literal() -> void:
	var literal_val1: int = forth.pop()
	var literal_val2: int = forth.pop()
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[two_literal_exec]
	)
	# store the value
	forth.ram.set_int(forth.dict_top + ForthRAM.CELL_SIZE, literal_val1)
	forth.ram.set_int(forth.dict_top + ForthRAM.DCELL_SIZE, literal_val2)
	forth.dict_top += ForthRAM.CELL_SIZE * 3  # three cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX 2LITERAL
func two_literal_exec() -> void:
	# execution time functionality of literal
	# return contents of cell after execution token
	forth.push(forth.ram.get_int(forth.dict_ip + ForthRAM.DCELL_SIZE))
	forth.push(forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE))
	# advance the instruction pointer by one to skip over the data
	forth.dict_ip += ForthRAM.DCELL_SIZE


## @WORD 2VARIABLE
## Create a dictionary entry for name associated with two cells of data.
## Executing <name> returns the address of the allocated cells.
## @STACK Compile: ( "name" - ), Execute: ( - addr )
func two_variable() -> void:
	forth.core.create()
	# make room for one cell
	forth.dict_top += ForthRAM.DCELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORD D.
## Display the top cell pair on the stack as a signed double integer.
## @STACK ( d - )
func d_dot() -> void:
	var fmt: String = "%d" if forth.ram.get_int(forth.BASE) == 10 else "%x"
	forth.util.print_term(" " + fmt % forth.pop_dint())


## @WORD D-
## Subtract d2 from d1, leaving the difference d3.
## @STACK ( d1 d2 - d3 )
func d_minus() -> void:
	var t: int = forth.pop_dint()
	forth.push_dint(forth.pop_dint() - t)


## @WORD D+
## Add d1 to d2, leaving the sum d3.
## @STACK ( d1 d2 - d3 )
func d_plus() -> void:
	forth.push_dint(forth.pop_dint() + forth.pop_dint())


## @WORD D<
## Return true if and only if d1 is less than d2.
## @STACK ( d1 d2 - flag )
func d_less_than() -> void:
	var t: int = forth.pop_dint()
	if forth.pop_dint() < t:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD D=
## Return true if and only if d1 is equal to d2.
## @STACK ( d1 d2 - flag )
func d_equals() -> void:
	var t: int = forth.pop_dint()
	if forth.pop_dint() == t:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD D0<
## Return true if and only if the double precision value d is less than zero.
## @STACK ( d - flag )
func d_zero_less() -> void:
	if forth.pop_dint() < 0:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD D0=
## Return true if and only if the double precision value d is equal to zero.
## @STACK ( d - flag )
func d_zero_equal() -> void:
	if forth.pop_dint() == 0:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD D2*
## Multiply d1 by 2, leaving the result d2.
## @STACK ( d1 - d2 )
func d_two_star() -> void:
	forth.set_dint(0, forth.get_dint(0) * 2)


## @WORD D2/
## Divide d1 by 2, leaving the result d2.
## @STACK ( d1 - d2 )
func d_two_slash() -> void:
	forth.set_dint(0, forth.get_dint(0) / 2)


## @WORD D>S
## Convert double to single, discarding MS cell.
## @STACK ( d - n )
func d_to_s() -> void:
	# this assumes doubles are pushed in LS MS order
	forth.pop()


## @WORD DABS
## Replace the top stack double item with its absolute value.
## @STACK ( d - +d )
func d_abs() -> void:
	forth.set_dint(0, abs(forth.get_dint(0)))


## @WORD DMAX
## Return d3, the greater of d1 and d2.
## @STACK ( d1 d2 - d3 )
func d_max() -> void:
	var d2: int = forth.pop_dint()
	if d2 > forth.get_dint(0):
		forth.set_dint(0, d2)


## @WORD DMIN
## Return d3, the lesser of d1 and d2.
## @STACK ( d1 d2 - d3 )
func d_min() -> void:
	var d2: int = forth.pop_dint()
	if d2 < forth.get_dint(0):
		forth.set_dint(0, d2)


## @WORD DNEGATE
## Change the sign of the top stack value.
## @STACK ( d - -d )
func d_negate() -> void:
	forth.set_dint(0, -forth.get_dint(0))


## @WORD M*/
## Multiply d1 by n1 producing a triple cell intermediate result t.
## Divide t by n2, giving quotient d2.
## @STACK ( d1 n1 +n2 - d2 )
func m_star_slash() -> void:
	# Following is an *approximate* implementation, using the double float
	var n2: int = forth.pop()
	var n1: int = forth.pop()
	var d1: int = forth.pop_dint()
	forth.push_dint(int((float(d1) / n2) * n1))


## @WORD M+
## Add n to d1 leaving the sum d2.
## @STACK ( d1 n - d2 )
func m_plus() -> void:
	var n: int = forth.pop()
	forth.push_dint(forth.pop_dint() * n)
