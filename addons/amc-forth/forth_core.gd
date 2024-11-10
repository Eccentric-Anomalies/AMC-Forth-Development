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
	forth.push_word(")".to_ascii_buffer()[0])
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
	var t: int = (
		forth.ram.get_int(forth.ds_p)
		+ forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


## @WORD -
func minus() -> void:
	# subtract n2 from n1, leaving the diference n3
	# ( n1 n2 - n3 )
	var t: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		- forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


## @WORD ,
func comma() -> void:
	# Reserve one cell of data space and store x in it.
	# ( x - )
	forth.ram.set_word(forth.dict_top, forth.pop_word())
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORD .
func dot() -> void:
	var fmt: String = "%d" if forth.ram.get_word(forth.BASE) == 10 else "%x"
	forth.util.print_term(" " + fmt % forth.pop_int())


## @WORD 1+
func one_plus() -> void:
	# Add one to n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) + 1)


## @WORD 1-
func one_minus() -> void:
	# Subtract one from n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) - 1)


## @WORD '
func tick() -> void:
	# Search the dictionary for name and leave its execution token
	# on the stack. Abort if name cannot be found.
	# ( - xt ) <name>
	# retrieve the name token
	forth.push_word(ForthTerminal.BL.to_ascii_buffer()[0])
	word()
	count()
	var len: int = forth.pop_word()  # length
	var caddr: int = forth.pop_word()  # start
	var word: String = forth.util.str_from_addr_n(caddr, len)
	# look the name up
	var token_addr = forth.find_in_dict(word)
	# either in user dictionary, a built-in xt, or neither
	if token_addr:
		forth.push_word(token_addr)
	else:
		token_addr = forth.xt_from_word(word)
		if token_addr in forth.built_in_function_from_address:
			forth.push_word(token_addr)
		else:
			forth.util.print_unknown_word(word)


## @WORD !
func store() -> void:
	# Store x in the cell at a-addr
	# ( x a-addr - )
	var addr: int = forth.pop_word()
	forth.ram.set_word(addr, forth.pop_word())


## @WORD *
func star() -> void:
	# Multiply n1 by n2 leaving the product n3
	# ( n1 n2 - n3 )
	var t: int = (
		forth.ram.get_int(forth.ds_p)
		* forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


## @WORD */
func star_slash() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell quotient n4.
	# ( n1 n2 n3 - n4 )
	var p: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		* forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE * 2)
	)
	var q: int = p / forth.ram.get_int(forth.ds_p)
	forth.ds_p += ForthRAM.CELL_SIZE * 2
	forth.ram.set_int(forth.ds_p, q)


## @WORD */MOD
func star_slash_mod() -> void:
	# Multiply n1 by n2 producing a double-cell result d.
	# Divide d by n3, giving the single-cell remainder n4
	# and a single-cell quotient n5
	# ( n1 n2 n3 - n4 n5 )
	var p: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		* forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE * 2)
	)
	var r: int = p % forth.ram.get_int(forth.ds_p)
	var q: int = p / forth.ram.get_int(forth.ds_p)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, q)  # quotient
	forth.ram.set_int(forth.ds_p + ForthRAM.CELL_SIZE, r)  # remainder


## @WORD /
func slash() -> void:
	# divide n1 by n2, leaving the quotient n3
	# ( n1 n2 - n3 )
	var t: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		/ forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


## @WORD /MOD
func slash_mod() -> void:
	# divide n1 by n2, leaving the remainder n3 and quotient n4
	# ( n1 n2 - n3 n4 )
	var q: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		/ forth.ram.get_int(forth.ds_p)
	)
	var r: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		% forth.ram.get_int(forth.ds_p)
	)
	forth.ram.set_int(forth.ds_p, q)
	forth.ram.set_int(forth.ds_p + ForthRAM.CELL_SIZE, r)


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
		forth.push_word(forth.ram.get_word(forth.dict_ip))
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
		forth.dict_top,
		forth.address_from_built_in_function[semi_colon_exec]
	)
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX ;
func semi_colon_exec() -> void:
	# Execution behavior of semi-colon
	exit()


## @WORD ?DUP
func q_dup() -> void:
	# ( x - 0 | x x )
	var t: int = forth.ram.get_int(forth.ds_p)
	if t != 0:
		forth.push_word(t)


## @WORD 2*
func two_star() -> void:
	# Return x2, result of shifting x1 one bit towards the MSB,
	# filling the LSB with zero
	# ( x1 - x2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) << 1)


## @WORD 2/
func two_slash() -> void:
	# Return x2, result of shifting x1 one bit towards LSB,
	# leaving the MSB unchanged
	# ( x1 - x2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) >> 1)


## @WORD 2DROP
func two_drop() -> void:
	# remove the top pair of cells from the stack
	# ( x1 x2 - )
	forth.pop_dword()


## @WORD 2DUP
func two_dup() -> void:
	# duplicate the top cell pair
	# (x1 x2 - x1 x2 x1 x2 )
	var t: int = forth.ram.get_dword(forth.ds_p)
	forth.push_dword(t)


## @WORD 2OVER
func two_over() -> void:
	# copy a cell pair x1 x2 to the top of the stack
	# ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
	forth.ds_p -= ForthRAM.DCELL_SIZE
	forth.ram.set_dword(
		forth.ds_p, forth.ram.get_dword(forth.ds_p + 2 * ForthRAM.DCELL_SIZE)
	)


## @WORD 2SWAP
func two_swap() -> void:
	# exchange the top two cell pairs
	# ( x1 x2 x3 x4 - x3 x4 x1 x2 )
	var t: int = forth.ram.get_dword(forth.ds_p + ForthRAM.DCELL_SIZE)
	forth.ram.set_dword(
		forth.ds_p + ForthRAM.DCELL_SIZE, forth.ram.get_dword(forth.ds_p)
	)
	forth.ram.set_dword(forth.ds_p, t)


## @WORD >IN
func to_in() -> void:
	# Return address of a cell containing the offset, in characters,
	# from the start of the input buffer to the start of the current
	# parse position
	# ( - a-addr )
	forth.push_word(forth.BUFF_TO_IN)


## @WORD @
func fetch() -> void:
	# Replace a-addr with the contents of the cell at a_addr
	# ( a_addr - x )
	forth.push_word(forth.ram.get_word(forth.pop_word()))


## @WORD ABS
func f_abs() -> void:
	# Replace the top stack item with its absolute value
	# ( n - +n )
	forth.ram.set_word(forth.ds_p, abs(forth.ram.get_int(forth.ds_p)))


## @WORD ALIGN
func align() -> void:
	# If the data-space pointer is not aligned reserve space to align it
	# ( - )
	forth.push_word(forth.dict_top)
	aligned()
	forth.dict_top = forth.pop_word()
	# preserve dictionary state
	forth.save_dict_top()


## @WORD ALIGNED
func aligned() -> void:
	# Return a-addr, the first aligned address greater than or equal to addr
	# ( addr - a-addr )
	var a: int = forth.pop_word()
	if a % ForthRAM.CELL_SIZE:
		a = (a / ForthRAM.CELL_SIZE + 1) * ForthRAM.CELL_SIZE
	forth.push_word(a)


## @WORD ALLOT
func allot() -> void:
	# Allocate u bytes of data space beginning at the next location.
	# ( u - )
	forth.dict_top += forth.pop_word()
	# preserve dictionary state
	forth.save_dict_top()


## @WORD AND
func f_and() -> void:
	# Return x3, the bit-wise logical and of x1 and x2
	# ( x1 x2 - x3)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_word(
		forth.ds_p,
		(
			forth.ram.get_word(forth.ds_p)
			& forth.ram.get_word(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)


## @WORD BASE
func base() -> void:
	# Return a-addr, the address of a cell containing the current number
	# conversion radix, between 2 and 36 inclusive.
	# ( - a-addr )
	forth.push_word(forth.BASE)


## @WORD BL
func b_l() -> void:
	# Return char, the ASCII character value of a space
	# ( - char )
	forth.push_word(int(ForthTerminal.BL))


## @WORD CELL+
func cell_plus() -> void:
	# Add the size in bytes of a cell to a_addr1, returning a_addr2
	# ( a-addr1 - a-addr2 )
	forth.push_word(ForthRAM.CELL_SIZE)
	plus()


## @WORD CELLS
func cells() -> void:
	# Return n2, the size in bytes of n1 cells
	# ( n1 - n2 )
	forth.push_word(ForthRAM.CELL_SIZE)
	star()


## @WORD C,
func c_comma() -> void:
	# Rserve one byte of data space and store char in the byte
	# ( char - )
	forth.ram.set_byte(forth.dict_top, forth.pop_word())
	forth.dict_top += 1
	# preserve dictionary state
	forth.save_dict_top()


## @WORD CHAR+
func char_plus() -> void:
	# Add the size in bytes of a character to c_addr1, giving c-addr2
	# ( c-addr1 - c-addr2 )
	forth.push_word(1)
	plus()


## @WORD CHARS
func chars() -> void:
	# Return n2, the size in bytes of n1 characters. May be a no-op.
	pass


## @WORD CONSTANT
func constant() -> void:
	# Create a dictionary entry for name, associated with constant x.
	# ( x - )
	var init_val: int = forth.pop_word()
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
	forth.push_word(forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE))


## @WORD COUNT
func count() -> void:
	# Return the length n, and address of the text portion of a counted string
	# ( c_addr1 - c_addr2 u )
	var addr: int = forth.pop_word()
	forth.push_word(addr + 1)
	forth.push_word(forth.ram.get_byte(addr))


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
	forth.push_word(forth.dict_ip + ForthRAM.CELL_SIZE)


## @WORD DECIMAL
func decimal() -> void:
	# Sets BASE to 10
	# ( - )
	forth.push_word(10)
	base()
	store()


## @WORD DEPTH
func depth() -> void:
	# ( - +n )
	forth.push_word((forth.DS_TOP - forth.ds_p) / ForthRAM.CELL_SIZE)


## @WORD DUP
func dup() -> void:
	# ( x - x x )
	var t: int = forth.ram.get_int(forth.ds_p)
	forth.push_word(t)


## @WORD DROP
func drop() -> void:
	# ( x - )
	forth.pop_word()


## @WORD EMIT
func emit() -> void:
	# Output one character from the LSB of the top item on stack.
	# ( b - )
	var c: int = forth.pop_word()
	forth.util.print_term(char(c))


## @WORD EXECUTE
func execute() -> void:
	# Remove execution token xt from the stack and perform
	# the execution behavior it identifies
	# ( xt - )
	var xt: int = forth.pop_word()
	if xt in forth.built_in_function_from_address:
		# this xt identifies a gdscript function
		forth.built_in_function_from_address[xt].call()
	elif xt >= forth.DICT_START and xt < forth.DICT_TOP:
		# save the current ip
		forth.push_ip()
		# this is a physical address of an xt
		forth.dict_ip = xt
		# push the xt
		forth.push_word(forth.ram.get_word(xt))
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
	forth.push_word(forth.dict_top)


## @WORD INVERT
func invert() -> void:
	# Invert all bits of x1, giving its logical inverse x2
	# ( x1 - x2 )
	forth.ram.set_word(forth.ds_p, ~forth.ram.get_word(forth.ds_p))


## @WORD LSHIFT
func lshift() -> void:
	# Perform a logical left shift of u places on x1, giving x2._add_constant_central_force
	# Fill the vacated LSB bits with zero
	# (x1 u - x2 )
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(
		forth.ds_p,
		(
			forth.ram.get_int(forth.ds_p)
			<< forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)


## @WORD M*
func m_star() -> void:
	# Multiply n1 by n2, leaving the double result d.
	# ( n1 n2 - d )
	forth.ram.set_dint(
		forth.ds_p,
		(
			forth.ram.get_int(forth.ds_p)
			* forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		)
	)


## @WORD MAX
func max() -> void:
	# Return n3, the greater of n1 and n2
	# ( n1 n2 - n3 )
	forth.ds_p += ForthRAM.CELL_SIZE
	var lt: bool = (
		forth.ram.get_int(forth.ds_p)
		< forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
	)
	if lt:
		forth.ram.set_int(
			forth.ds_p, forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)


## @WORD MIN
func min() -> void:
	# Return n3, the lesser of n1 and n2
	# ( n1 n2 - n3 )
	forth.ds_p += ForthRAM.CELL_SIZE
	var gt: bool = (
		forth.ram.get_int(forth.ds_p)
		> forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
	)
	if gt:
		forth.ram.set_int(
			forth.ds_p, forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)


## @WORD MOD
func mod() -> void:
	# Divide n1 by n2, giving the remainder n3
	# (n1 n2 - n3 )
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(
		forth.ds_p,
		(
			forth.ram.get_int(forth.ds_p)
			% forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)


## @WORD MOVE
func move() -> void:
	# Copy u byes from a source starting at addr1 to the destination
	# starting at addr2. This works even if the ranges overlap.
	# ( addr1 addr2 u - )
	var a1: int = forth.ram.get_word(forth.ds_p + 2 * ForthRAM.CELL_SIZE)
	var a2: int = forth.ram.get_word(forth.ds_p + ForthRAM.CELL_SIZE)
	var u: int = forth.ram.get_word(forth.ds_p)
	if a1 == a2 or u == 0:
		# string doesn't need to move. Clean the stack and return.
		drop()
		two_drop()
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
	forth.ram.set_int(forth.ds_p, -forth.ram.get_int(forth.ds_p))


## @WORD OR
func f_or() -> void:
	# Return x3, the bit-wise inclusive or of x1 with x2
	# ( x1 x2 - x3 )
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_word(
		forth.ds_p,
		(
			forth.ram.get_word(forth.ds_p)
			| forth.ram.get_word(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)


## @WORD OVER
func over() -> void:
	# place a copy of x1 on top of the stack
	# ( x1 x2 - x1 x2 x1 )
	forth.ds_p -= ForthRAM.CELL_SIZE
	forth.ram.set_int(
		forth.ds_p, forth.ram.get_int(forth.ds_p + 2 * ForthRAM.CELL_SIZE)
	)


## @WORD ROT
func rot() -> void:
	# rotate the top three items on the stack
	# ( x1 x2 x3 - x2 x3 x1 )
	var t: int = forth.ram.get_int(forth.ds_p + 2 * ForthRAM.CELL_SIZE)
	forth.ram.set_int(
		forth.ds_p + 2 * ForthRAM.CELL_SIZE,
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	)
	forth.ram.set_int(
		forth.ds_p + ForthRAM.CELL_SIZE, forth.ram.get_int(forth.ds_p)
	)
	forth.ram.set_int(forth.ds_p, t)


## @WORD RSHIFT
func rshift() -> void:
	# Perform a logical right shift of u places on x1, giving x2.
	# Fill the vacated MSB bits with zeroes
	# ( x1 u - x2 )
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(
		forth.ds_p,
		(
			forth.ram.get_word(forth.ds_p)
			>> forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)


## @WORD S>D
func s_to_d() -> void:
	# Convert a single cell number n to its double equivalent d
	# ( n - d )
	var t: int = forth.ram.get_int(forth.ds_p)
	forth.ds_p += ForthRAM.CELL_SIZE - ForthRAM.DCELL_SIZE
	forth.ram.set_dint(forth.ds_p, t)


## @WORD SM/REM
func sm_slash_rem() -> void:
	# Divide d by n1, using symmetric division, giving quotient n3 and
	# remainder n2. All arguments are signed.
	# ( d n1 - n2 n3 )
	var dd: int = forth.ram.get_dint(forth.ds_p + ForthRAM.CELL_SIZE)
	var d: int = forth.ram.get_int(forth.ds_p)
	var q: int = dd / d
	var r: int = dd % d
	forth.ds_p += ForthRAM.DCELL_SIZE - ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, q)
	forth.ram.set_int(forth.ds_p + ForthRAM.CELL_SIZE, r)


## @WORD SOURCE
func source() -> void:
	# Return the address and length of the input buffer
	# ( - c-addr u )
	forth.push_word(forth.BUFF_SOURCE_START)
	forth.push_word(forth.BUFF_SOURCE_SIZE)


## @WORD SWAP
func swap() -> void:
	# exchange the top two items on the stack
	# ( x1 x2 - x2 x1 )
	var t: int = forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	forth.ram.set_int(
		forth.ds_p + ForthRAM.CELL_SIZE, forth.ram.get_int(forth.ds_p)
	)
	forth.ram.set_int(forth.ds_p, t)


## @WORD WORD
func word() -> void:
	# Skip leading occurrences of the delimiter char. Parse text
	# deliminted by char. Return the address of a temporary location
	# containing the pased text as a counted string
	# ( char - c-addr )
	dup()
	var delim: int = forth.pop_word()
	source()
	var source_size: int = forth.pop_word()
	var source_start: int = forth.pop_word()
	to_in()
	var ptraddr: int = forth.pop_word()
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
	var count: int = forth.pop_word()
	var straddr: int = forth.pop_word()
	var ret: int = straddr - 1
	forth.ram.set_byte(ret, count)
	forth.push_word(ret)


## @WORD TYPE
func type() -> void:
	# Output the characer string at c-addr, length u
	# ( c-addr u - )
	var l: int = forth.pop_word()
	var s: int = forth.pop_word()
	for i in l:
		forth.push_word(forth.ram.get_byte(s + i))
		emit()


## @WORD UM*
func um_star() -> void:
	# Multiply u1 by u2, leaving the double-precision result ud
	# ( u1 u2 - ud )
	forth.ram.set_dword(
		forth.ds_p,
		(
			forth.ram.get_word(forth.ds_p + ForthRAM.CELL_SIZE)
			* forth.ram.get_word(forth.ds_p)
		)
	)


## @WORD UM/MOD
func um_slash_mod() -> void:
	# Divide ud by n1, leaving quotient n3 and remainder n2.
	# All arguments and result are unsigned.
	# ( d u1 - u2 u3 )
	var dd: int = forth.ram.get_dword(forth.ds_p + ForthRAM.CELL_SIZE)
	var d: int = forth.ram.get_word(forth.ds_p)
	var q: int = dd / d
	var r: int = dd % d
	forth.ds_p += ForthRAM.DCELL_SIZE - ForthRAM.CELL_SIZE
	forth.ram.set_word(forth.ds_p, q)
	forth.ram.set_word(forth.ds_p + ForthRAM.CELL_SIZE, r)


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
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_word(
		forth.ds_p,
		(
			forth.ram.get_word(forth.ds_p)
			^ forth.ram.get_word(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)
