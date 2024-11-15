class_name ForthCore  # gdlint:ignore = max-public-methods
## Define built-in Forth words in the CORE word set
##

extends ForthImplementationBase

var _smudge_address: int = 0


## Initialize (executed automatically by ForthCore.new())
##
## (1) All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## (2) All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
## (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
func _init(_forth: AMCForth) -> void:
	super(_forth)


## Utility function for parsing comments
func start_parenthesis() -> void:
	forth.push(")".to_ascii_buffer()[0])
	forth.core_ext.parse()


## @WORD (
func left_parenthesis() -> void:
	# Begin parsing a comment, terminated by ')' character
	# ( - )
	start_parenthesis()
	forth.core.two_drop()


## @WORD +
func plus() -> void:
	# Add n1 to n2 leaving the sum n3
	# ( n1 n2 - n3 )
	forth.push((forth.pop() + forth.pop()) & ForthRAM.CELL_MASK)


## @WORD -
func minus() -> void:
	# subtract n2 from n1, leaving the diference n3
	# ( n1 n2 - n3 )
	var n: int = forth.pop()
	forth.push((forth.pop() - n) & ForthRAM.CELL_MASK)


## @WORD ,
func comma() -> void:
	# Reserve one cell of data space and store x in it.
	# ( x - )
	forth.ram.set_word(forth.dict_top, forth.pop())
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORD .
func dot() -> void:
	var fmt: String = "%d" if forth.ram.get_word(forth.BASE) == 10 else "%x"
	forth.util.print_term(" " + fmt % forth.pop())


## @WORD 1+
func one_plus() -> void:
	# Add one to n1, leaving n2
	# ( n1 - n2 )
	forth.data_stack[forth.ds_p] += 1
	forth.data_stack[forth.ds_p] &= ForthRAM.CELL_MASK


## @WORD 1-
func one_minus() -> void:
	# Subtract one from n1, leaving n2
	# ( n1 - n2 )
	forth.data_stack[forth.ds_p] -= 1
	forth.data_stack[forth.ds_p] &= ForthRAM.CELL_MASK


## @WORD '
func tick() -> void:
	# Search the dictionary for name and leave its execution token
	# on the stack. Abort if name cannot be found.
	# ( - xt ) <name>
	# retrieve the name token
	forth.push(ForthTerminal.BL.to_ascii_buffer()[0])
	word()
	count()
	var len: int = forth.pop()  # length
	var caddr: int = forth.pop()  # start
	var word: String = forth.util.str_from_addr_n(caddr, len)
	# look the name up
	var token_addr_immediate = forth.find_in_dict(word)
	# either in user dictionary, a built-in xt, or neither
	if token_addr_immediate[0]:
		forth.push(token_addr_immediate[0])
	else:
		var token_addr: int = forth.xt_from_word(word)
		if token_addr in forth.built_in_function_from_address:
			forth.push(token_addr)
		else:
			forth.util.print_unknown_word(word)


## @WORD !
func store() -> void:
	# Store x in the cell at a-addr
	# ( x a-addr - )
	var addr: int = forth.pop()
	forth.ram.set_word(addr, forth.pop())


## @WORD *
func star() -> void:
	# Multiply n1 by n2 leaving the product n3
	# ( n1 n2 - n3 )
	forth.push(forth.ram.truncate_to_cell(forth.pop() * forth.pop()))


## @WORD */
func star_slash() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell quotient n4.
	# ( n1 n2 n3 - n4 )
	var d: int = forth.pop()
	forth.push((forth.pop() * forth.pop() / d) & ForthRAM.CELL_MASK)


## @WORD */MOD
func star_slash_mod() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell remainder n4
	# and a single-cell quotient n5
	# ( n1 n2 n3 - n4 n5 )
	var d: int = forth.pop()
	var p: int = forth.pop() * forth.pop()
	forth.push(p % d)
	forth.push(p / d)


## @WORD /
func slash() -> void:
	# divide n1 by n2, leaving the quotient n3
	# ( n1 n2 - n3 )
	var d: int = forth.pop()
	forth.push(forth.pop() / d)


## @WORD /MOD
func slash_mod() -> void:
	# divide n1 by n2, leaving the remainder n3 and quotient n4
	# ( n1 n2 - n3 n4 )
	var div: int = forth.pop()
	var d: int = forth.pop()
	forth.push(d % div)
	forth.push(d / div)


## @WORD : <name>
func colon() -> void:
	# Create a definition for name and enter compilation state
	# ( - )
	_smudge_address = forth.create_dict_entry_name(true)
	if _smudge_address:
		# enter compile state
		forth.state = true
		forth.ram.set_word(
			forth.dict_top, forth.address_from_built_in_function[colon_exec]
		)
		forth.dict_top += ForthRAM.CELL_SIZE
		# preserve dictionary state
		forth.save_dict_top()


## @WORDX :
func colon_exec() -> void:
	# Execution behavior of colon
	# save the current stack level
	while not forth.exit_flag:
		# Step to the next item
		forth.dict_ip += ForthRAM.CELL_SIZE
		# get the next execution token
		forth.push(forth.ram.get_word(forth.dict_ip))
		# and do what it says to do!
		execute()
	# we are exiting. reset the flag.
	forth.exit_flag = false


## @WORD ; IMMEDIATE
func semi_colon() -> void:
	# Leave compilation state
	# ( - )
	# remove the smudge bit
	forth.ram.set_byte(
		_smudge_address,
		forth.ram.get_byte(_smudge_address) & ~forth.SMUDGE_BIT_MASK
	)
	# clear compile state
	forth.state = false
	# insert the XT for the semi-colon
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[semi_colon_exec]
	)
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()
	# check for control flow stack integrity
	if not forth.cf_stack_is_empty():
		forth.util.rprint_term("Unbalanced control structure")
		# empty the stack
		while not forth.cf_stack_is_empty():
			forth.cf_pop()


## @WORDX ;
func semi_colon_exec() -> void:
	# Execution behavior of semi-colon
	exit()


## @WORD ?DUP
func q_dup() -> void:
	# ( x - 0 | x x )
	var n: int = forth.data_stack[forth.ds_p]
	if n != 0:
		forth.push(n)


## @WORD 2*
func two_star() -> void:
	# Return x2, result of shifting x1 one bit towards the MSB,
	# filling the LSB with zero
	# ( x1 - x2 )
	forth.push(forth.ram.truncate_to_cell(forth.pop() << 1))


## @WORD 2/
func two_slash() -> void:
	# Return x2, result of shifting x1 one bit towards LSB,
	# leaving the MSB unchanged
	# ( x1 - x2 )
	var msb: int = forth.data_stack[forth.ds_p] & ForthRAM.CELL_MSB_MASK
	var n: int = forth.data_stack[forth.ds_p]
	# preserve msbit
	forth.data_stack[forth.ds_p] = (n >> 1) | msb


## @WORD 2DROP
func two_drop() -> void:
	# remove the top pair of cells from the stack
	# ( x1 x2 - )
	forth.pop()
	forth.pop()


## @WORD 2DUP
func two_dup() -> void:
	# duplicate the top cell pair
	# (x1 x2 - x1 x2 x1 x2 )
	var x2: int = forth.data_stack[forth.ds_p]
	var x1: int = forth.data_stack[forth.ds_p + 1]
	forth.push(x1)
	forth.push(x2)


## @WORD 2LITERAL
func two_literal() -> void:
	# At compile time, remove the top two numbers from the stack and compile
	# into the current definition.
	# ( - x x )  (runtime)
	var literal_val1: int = forth.pop()
	var literal_val2: int = forth.pop()
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[two_literal_exec]
	)
	# store the value
	forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, literal_val1)
	forth.ram.set_word(forth.dict_top + ForthRAM.DCELL_SIZE, literal_val2)
	forth.dict_top += ForthRAM.CELL_SIZE * 3  # three cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX 2LITERAL
func two_literal_exec() -> void:
	# execution time functionality of literal
	# return contents of cell after execution token
	forth.push(forth.ram.get_word(forth.dict_ip + ForthRAM.DCELL_SIZE))
	forth.push(forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE))
	# advance the instruction pointer by one to skip over the data
	forth.dict_ip += ForthRAM.DCELL_SIZE


## @WORD 2OVER
func two_over() -> void:
	# copy a cell pair x1 x2 to the top of the stack
	# ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
	var x2: int = forth.data_stack[forth.ds_p + 2]
	var x1: int = forth.data_stack[forth.ds_p + 3]
	forth.push(x1)
	forth.push(x2)


## @WORD 2SWAP
func two_swap() -> void:
	# exchange the top two cell pairs
	# ( x1 x2 x3 x4 - x3 x4 x1 x2 )
	var x2: int = forth.data_stack[forth.ds_p + 2]
	var x1: int = forth.data_stack[forth.ds_p + 3]
	forth.data_stack[forth.ds_p + 3] = forth.data_stack[forth.ds_p + 1]
	forth.data_stack[forth.ds_p + 2] = forth.data_stack[forth.ds_p]
	forth.data_stack[forth.ds_p + 1] = x1
	forth.data_stack[forth.ds_p] = x2


## @WORD >IN
func to_in() -> void:
	# Return address of a cell containing the offset, in characters,
	# from the start of the input buffer to the start of the current
	# parse position
	# ( - a-addr )
	forth.push(forth.BUFF_TO_IN)


## @WORD @
func fetch() -> void:
	# Replace a-addr with the contents of the cell at a_addr
	# ( a_addr - x )
	forth.push(forth.ram.get_word(forth.pop()))


## @WORD ABS
func f_abs() -> void:
	# Replace the top stack item with its absolute value
	# ( n - +n )
	forth.data_stack[forth.ds_p] = abs(forth.data_stack[forth.ds_p])


## @WORD AGAIN IMMEDIATE
func again() -> void:
	# Unconditionally branch back to the point immediately following
	# the nearest previous BEGIN
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[again_exec]
	)
	# The link back
	forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, forth.cf_pop())
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up and done


## @WORDX AGAIN
func again_exec() -> void:
	# Unconditionally branch
	forth.dict_ip = forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE)


## @WORD AHEAD IMMEDIATE
func ahead() -> void:
	# Place forward reference origin on the control flow stack.
	# ( - orig )
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[ahead_exec]
	)
	# leave link address on the control stack
	forth.cf_push(forth.dict_top + ForthRAM.CELL_SIZE)
	# move up to finish
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX AHEAD
func ahead_exec() -> void:
	# Branch to ELSE if top of stack not TRUE
	# ( x - )
	# Skip ahead to the address in the next cell
	forth.dict_ip = forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE)


## @WORD ALIGN
func align() -> void:
	# If the data-space pointer is not aligned reserve space to align it
	# ( - )
	forth.push(forth.dict_top)
	aligned()
	forth.dict_top = forth.pop()
	# preserve dictionary state
	forth.save_dict_top()


## @WORD ALIGNED
func aligned() -> void:
	# Return a-addr, the first aligned address greater than or equal to addr
	# ( addr - a-addr )
	var a: int = forth.pop()
	if a % ForthRAM.CELL_SIZE:
		a = (a / ForthRAM.CELL_SIZE + 1) * ForthRAM.CELL_SIZE
	forth.push(a)


## @WORD ALLOT
func allot() -> void:
	# Allocate u bytes of data space beginning at the next location.
	# ( u - )
	forth.dict_top += forth.pop()
	# preserve dictionary state
	forth.save_dict_top()


## @WORD AND
func f_and() -> void:
	# Return x3, the bit-wise logical and of x1 and x2
	# ( x1 x2 - x3)
	forth.push(forth.pop() & forth.pop())


## @WORD BASE
func base() -> void:
	# Return a-addr, the address of a cell containing the current number
	# conversion radix, between 2 and 36 inclusive.
	# ( - a-addr )
	forth.push(forth.BASE)


## @WORD BEGIN IMMEDIATE
func begin() -> void:
	# Mark the destination of a backward branch.
	# ( - )
	# backwards by one cell, so execution will advance it to the right point
	forth.cf_push(forth.dict_top - ForthRAM.CELL_SIZE)


## @WORD BL
func b_l() -> void:
	# Return char, the ASCII character value of a space
	# ( - char )
	forth.push(int(ForthTerminal.BL))


## @WORD CELL+
func cell_plus() -> void:
	# Add the size in bytes of a cell to a_addr1, returning a_addr2
	# ( a-addr1 - a-addr2 )
	forth.push(ForthRAM.CELL_SIZE)
	plus()


## @WORD CELLS
func cells() -> void:
	# Return n2, the size in bytes of n1 cells
	# ( n1 - n2 )
	forth.push(ForthRAM.CELL_SIZE)
	star()


## @WORD C,
func c_comma() -> void:
	# Rserve one byte of data space and store char in the byte
	# ( char - )
	forth.ram.set_byte(forth.dict_top, forth.pop())
	forth.dict_top += 1
	# preserve dictionary state
	forth.save_dict_top()


## @WORD CHAR+
func char_plus() -> void:
	# Add the size in bytes of a character to c_addr1, giving c-addr2
	# ( c-addr1 - c-addr2 )
	forth.push(1)
	plus()


## @WORD CHARS
func chars() -> void:
	# Return n2, the size in bytes of n1 characters. May be a no-op.
	pass


## @WORD CONSTANT
func constant() -> void:
	# Create a dictionary entry for name, associated with constant x.
	# ( x - )
	var init_val: int = forth.pop()
	if forth.create_dict_entry_name():
		# copy the execution token
		forth.ram.set_word(
			forth.dict_top, forth.address_from_built_in_function[constant_exec]
		)
		# store the constant
		forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, init_val)
		forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
		# preserve dictionary state
		forth.save_dict_top()


## @WORDX CONSTANT
func constant_exec() -> void:
	# execution time functionality of _constant
	# return contents of cell after execution token
	forth.push(forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE))


## @WORD COUNT
func count() -> void:
	# Return the length n, and address of the text portion of a counted string
	# ( c_addr1 - c_addr2 u )
	var addr: int = forth.pop()
	forth.push(addr + 1)
	forth.push(forth.ram.get_byte(addr))


## @WORD CREATE
func create() -> void:
	# Construct a dictionary entry for the next token in the input stream
	# Execution of *name* will return the address of its data space
	# ( - )
	if forth.create_dict_entry_name():
		forth.ram.set_word(
			forth.dict_top, forth.address_from_built_in_function[create_exec]
		)
		forth.dict_top += ForthRAM.CELL_SIZE
		# preserve dictionary state
		forth.save_dict_top()


## @WORDX CREATE
func create_exec() -> void:
	# execution time functionality of create
	# return address of cell after execution token
	forth.push(forth.dict_ip + ForthRAM.CELL_SIZE)


## @WORD DECIMAL
func decimal() -> void:
	# Sets BASE to 10
	# ( - )
	forth.push(10)
	base()
	store()


## @WORD DEPTH
func depth() -> void:
	# ( - +n )
	forth.push(forth.data_stack.size())


## @WORD DUP
func dup() -> void:
	# ( x - x x )
	forth.push(forth.data_stack[forth.ds_p])


## @WORD DROP
func drop() -> void:
	# ( x - )
	forth.pop()


## @WORD ELSE IMMEDIATE
func f_else() -> void:
	# At compile time, originate the true branch and and resolve he false.
	# ( - )
	ahead()
	forth.cf_stack_roll(1)
	f_then()


## @WORD EMIT
func emit() -> void:
	# Output one character from the LSB of the top item on stack.
	# ( b - )
	var c: int = forth.pop()
	forth.util.print_term(char(c))


## @WORD EXECUTE
func execute() -> void:
	# Remove execution token xt from the stack and perform
	# the execution behavior it identifies
	# ( xt - )
	var xt: int = forth.pop()
	if xt in forth.built_in_function_from_address:
		# this xt identifies a gdscript function
		forth.built_in_function_from_address[xt].call()
	elif xt >= forth.DICT_START and xt < forth.DICT_TOP:
		# save the current ip
		forth.push_ip()
		# this is a physical address of an xt
		forth.dict_ip = xt
		# push the xt
		forth.push(forth.ram.get_word(xt))
		# recurse down a layer
		execute()
		# restore our ip
		forth.pop_ip()
	else:
		forth.util.rprint_term(" Invalid execution token")


## @WORD EXIT
func exit() -> void:
	# Return control to the calling definition in the ip-stack
	# ( - )
	# set a flag indicating exit has been called
	forth.exit_flag = true


## @WORD HERE
func here() -> void:
	# Return address of the next available location in data-space
	# ( - addr )
	forth.push(forth.dict_top)


## @WORD IF IMMEDIATE
func f_if() -> void:
	# Place forward reference origin on the control flow stack.
	# ( - orig )
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[f_if_exec]
	)
	# leave link address on the control stack
	forth.cf_push(forth.dict_top + ForthRAM.CELL_SIZE)
	# move up to finish
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX IF
func f_if_exec() -> void:
	# Branch to ELSE if top of stack not TRUE
	# ( x - )
	if forth.pop() == 0:
		forth.dict_ip = forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE)
	else:
		# TRUE, so skip over the link and continue executing
		forth.dict_ip += ForthRAM.CELL_SIZE

## @WORD IMMEDIATE
	# Make the most recent definition an immediate word.
	# ( - )
	# This definition should be at the end of the dictionary
	# Set the IMMEDIATE bit in the name length byte
	if forth.dict_p != forth.dict_top:
		# dictionary is not empty, get the length of the top entry name
		var length_byte_addr = forth.dict_p + ForthRAM.CELL_SIZE
		# set the immediate bit in the length byte
		forth.ram.set_byte(
			length_byte_addr,
			forth.ram.get_byte(length_byte_addr) | forth.IMMEDIATE_BIT_MASK
		)


## @WORD INVERT
func invert() -> void:
	# Invert all bits of x1, giving its logical inverse x2
	# ( x1 - x2 )
	forth.data_stack[forth.ds_p] = ~forth.data_stack[forth.ds_p]


## @WORD LITERAL
func literal() -> void:
	# At compile time, remove the top number from the stack and compile
	# into the current definition.
	# ( - x )  (runtime)
	var literal_val: int = forth.pop()
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[literal_exec]
	)
	# store the value
	forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, literal_val)
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX LITERAL
func literal_exec() -> void:
	# execution time functionality of literal
	# return contents of cell after execution token
	forth.push(forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE))
	# advance the instruction pointer by one to skip over the data
	forth.dict_ip += ForthRAM.CELL_SIZE


## @WORD LSHIFT
func lshift() -> void:
	# Perform a logical left shift of u places on x1, giving x2._add_constant_central_force
	# Fill the vacated LSB bits with zero
	# (x1 u - x2 )
	swap()
	forth.push(forth.ram.truncate_to_cell(forth.pop() << forth.pop()))


## @WORD M*
func m_star() -> void:
	# Multiply n1 by n2, leaving the double result d.
	# ( n1 n2 - d )
	forth.push_dint(forth.pop() * forth.pop())


## @WORD MAX
func max() -> void:
	# Return n3, the greater of n1 and n2
	# ( n1 n2 - n3 )
	var n2: int = forth.pop()
	if n2 > forth.data_stack[forth.ds_p]:
		forth.data_stack[forth.ds_p] = n2


## @WORD MIN
func min() -> void:
	# Return n3, the lesser of n1 and n2
	# ( n1 n2 - n3 )
	var n2: int = forth.pop()
	if n2 < forth.data_stack[forth.ds_p]:
		forth.data_stack[forth.ds_p] = n2


## @WORD MOD
func mod() -> void:
	# Divide n1 by n2, giving the remainder n3
	# (n1 n2 - n3 )
	var n2: int = forth.pop()
	forth.push(forth.pop() % n2)


## @WORD MOVE
func move() -> void:
	# Copy u byes from a source starting at addr1 to the destination
	# starting at addr2. This works even if the ranges overlap.
	# ( addr1 addr2 u - )
	var a1: int = forth.data_stack[forth.ds_p + 2]
	var a2: int = forth.data_stack[forth.ds_p + 1]
	var u: int = forth.data_stack[forth.ds_p]
	if a1 == a2 or u == 0:
		# string doesn't need to move. Clean the stack and return.
		drop()
		drop()
		drop()
		return
	if a1 > a2:
		# potentially overlapping, source above dest
		forth.string.c_move()
	else:
		# potentially overlapping, source below dest
		forth.string.c_move_up()


## @WORD NEGATE
func negate() -> void:
	# Change the sign of the top stack value
	# ( n - -n )
	forth.data_stack[forth.ds_p] = -forth.data_stack[forth.ds_p]


## @WORD OR
func f_or() -> void:
	# Return x3, the bit-wise inclusive or of x1 with x2
	# ( x1 x2 - x3 )
	forth.push(forth.pop() | forth.pop())


## @WORD OVER
func over() -> void:
	# place a copy of x1 on top of the stack
	# ( x1 x2 - x1 x2 x1 )
	forth.push(forth.data_stack[forth.ds_p + 1])


## @WORD POSTPONE IMMEDIATE
func postpone() -> void:
	# At compile time, add the compilation behavior of the following
	# name, rather than its execution behavior.
	# ( - )
	# use tick to scan for the next word and obtain its execution token
	tick()
	# then store it in the current definition
	comma()


## @WORD ROT
func rot() -> void:
	# rotate the top three items on the stack
	# ( x1 x2 x3 - x2 x3 x1 )
	var t: int = forth.data_stack[forth.ds_p + 2]
	forth.data_stack[forth.ds_p + 2] = forth.data_stack[forth.ds_p + 1]
	forth.data_stack[forth.ds_p + 1] = forth.data_stack[forth.ds_p]
	forth.data_stack[forth.ds_p] = t


## @WORD RSHIFT
func rshift() -> void:
	# Perform a logical right shift of u places on x1, giving x2.
	# Fill the vacated MSB bits with zeroes
	# ( x1 u - x2 )
	var u: int = forth.pop()
	forth.data_stack[forth.ds_p] = (
		(forth.data_stack[forth.ds_p] >> u)
		& ~ForthRAM.CELL_MSB_MASK
		& ForthRAM.CELL_MASK
	)


## @WORD S>D
func s_to_d() -> void:
	# Convert a single cell number n to its double equivalent d
	# ( n - d )
	forth.push_dint(forth.pop())


## @WORD SM/REM
func sm_slash_rem() -> void:
	# Divide d by n1, using symmetric division, giving quotient n3 and
	# remainder n2. All arguments are signed.
	# ( d n1 - n2 n3 )
	var n1: int = forth.pop()
	var d: int = forth.pop_dint()
	forth.push(d % n1)
	forth.push(d / n1)


## @WORD SOURCE
func source() -> void:
	# Return the address and length of the input buffer
	# ( - c-addr u )
	forth.push(forth.BUFF_SOURCE_START)
	forth.push(forth.BUFF_SOURCE_SIZE)


## @WORD SWAP
func swap() -> void:
	# exchange the top two items on the stack
	# ( x1 x2 - x2 x1 )
	var x1: int = forth.data_stack[forth.ds_p + 1]
	forth.data_stack[forth.ds_p + 1] = forth.data_stack[forth.ds_p]
	forth.data_stack[forth.ds_p] = x1


## @WORD THEN IMMEDIATE
func f_then() -> void:
	# Place a reference to the this address at the address on the cf stack
	# ( - )
	# Note: this only places the forward reference to the position
	# just before this (the caller will step to the next location).
	# No f_then_exec function is needed.
	forth.ram.set_word(forth.cf_pop(), forth.dict_top - ForthRAM.CELL_SIZE)


## @WORD UNTIL IMMEDIATE
func until() -> void:
	# Conditionally branch back to the point immediately following
	# the nearest previous BEGIN
	# ( x - )
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[until_exec]
	)
	# The link back
	forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, forth.cf_pop())
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up and done


## @WORDX UNTIL
func until_exec() -> void:
	# ( x - )
	# Conditional branch
	if forth.pop() == 0:
		forth.dict_ip = forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE)
	else:
		# TRUE, so skip over the link and continue executing
		forth.dict_ip += ForthRAM.CELL_SIZE


## @WORD WORD
func word() -> void:
	# Skip leading occurrences of the delimiter char. Parse text
	# deliminted by char. Return the address of a temporary location
	# containing the pased text as a counted string
	# ( char - c-addr )
	dup()
	var delim: int = forth.pop()
	source()
	var source_size: int = forth.pop()
	var source_start: int = forth.pop()
	to_in()
	var ptraddr: int = forth.pop()
	while true:
		var t: int = forth.ram.get_byte(
			source_start + forth.ram.get_word(ptraddr)
		)
		if t == delim:
			# increment the input pointer
			forth.ram.set_word(ptraddr, forth.ram.get_word(ptraddr) + 1)
		else:
			break
	forth.core_ext.parse()
	var count: int = forth.pop()
	var straddr: int = forth.pop()
	var ret: int = straddr - 1
	forth.ram.set_byte(ret, count)
	forth.push(ret)


## @WORD TYPE
func type() -> void:
	# Output the characer string at c-addr, length u
	# ( c-addr u - )
	var l: int = forth.pop()
	var s: int = forth.pop()
	for i in l:
		forth.push(forth.ram.get_byte(s + i))
		emit()


## @WORD UM*
func um_star() -> void:
	# Multiply u1 by u2, leaving the double-precision result ud
	# ( u1 u2 - ud )
	forth.push_dword(forth.pop() * forth.pop())


## @WORD UM/MOD
func um_slash_mod() -> void:
	# Divide ud by n1, leaving quotient n3 and remainder n2.
	# All arguments and result are unsigned.
	# ( d u1 - u2 u3 )
	var u1: int = forth.pop()
	var d: int = forth.pop_dword()
	forth.push(d % u1)
	forth.push(d / u1)


## @WORD VARIABLE
func variable() -> void:
	# Create a dictionary entry for name associated with one cell of data
	# ( - )
	forth.core.create()
	# make room for one cell
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORD XOR
func xor() -> void:
	# Return x3, the bit-wise exclusive or of x1 with x2
	# ( x1 x2 - x3 )
	forth.push(forth.pop() ^ forth.pop())

# gdlint:ignore = max-file-lines
