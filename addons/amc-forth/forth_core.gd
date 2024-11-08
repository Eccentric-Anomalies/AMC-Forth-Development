class_name ForthCore  # gdlint:ignore = max-public-methods

extends ForthImplementationBase


func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				["(", left_parenthesis],  # core
				["+", plus],  # core
				["-", minus],  # core
				[",", comma],  # core
				[".", dot],  # core
				["1+", one_plus],  # core
				["1-", one_minus],  # core
				["'", tick],  # core
				["!", store],  # core
				["*", star],  # core
				["*/", star_slash],  # core
				["*/MOD", star_slash_mod],  # core
				["/", slash],  # core
				["/MOD", slash_mod],  # core
				["?DUP", q_dup],  # core
				["2*", two_star],  # core
				["2/", two_slash],  # core
				["2DROP", two_drop],  # core
				["2DUP", two_dup],  # core
				["2OVER", two_over],  # core
				["2SWAP", two_swap],  # core
				[">IN", to_in],  # core
				["@", fetch],  # core
				["ABS", f_abs],  # core
				["ALLOT", allot],  # core
				["AND", f_and],  # core
				["BL", b_l],  # core
				["CELL+", cell_plus],  # core
				["CELLS", cells],  # core
				["C,", c_comma],  # core
				["CHAR+", char_plus],  # core
				["CHARS", chars],  # core
				["CONSTANT", constant],  # core
				["COUNT", count],  # core
				["CREATE", create],  # core
				["DEPTH", depth],  # core
				["DUP", dup],  # core
				["DROP", drop],  # core
				["EMIT", emit],  # core
				["EXECUTE", execute],  # core
				["HERE", here],  # core
				["INVERT", invert],  # core
				["LSHIFT", lshift],  # core
				["M*", m_star],  # core
				["MAX", max],  # core
				["MIN", min],  # core
				["MOD", mod],  # core
				["MOVE", move],  # core
				["NEGATE", negate],  # core
				["OR", f_or],  # core
				["OVER", over],  # core
				["ROT", rot],  # core
				["RSHIFT", rshift],  # core
				["S>D", s_to_d],  # core
				["SM/REM", sm_slash_rem],  # core
				["SWAP", swap],  # core
				["SOURCE", source],  # core
				["TYPE", type],  # core
				["UM*", um_star],  # core
				["UM/MOD", um_slash_mod],  # core
				["VARIABLE", variable],  # core
				["XOR", xor],  # core
				["WORD", word],  # core
			]
		)
	)
	(
		forth
		. built_in_exec_functions
		. append_array(
			[
				constant_exec,
				create_exec,
			]
		)
	)


# Comments
func start_parenthesis() -> void:
	forth.push_word(")".to_ascii_buffer()[0])
	forth.parse()


func left_parenthesis() -> void:
	# Begin parsing a comment, terminated by ')' character
	# ( - )
	start_parenthesis()
	forth.two_drop()


func plus() -> void:
	# Add n1 to n2 leaving the sum n3
	# ( n1 n2 - n3 )
	var t: int = (
		forth.ram.get_int(forth.ds_p)
		+ forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


func minus() -> void:
	# subtract n2 from n1, leaving the diference n3
	# ( n1 n2 - n3 )
	var t: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		- forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


func comma() -> void:
	# Reserve one cell of data space and store x in it.
	# ( x - )
	forth.ram.set_word(forth.dict_top, forth.pop_word())
	forth.dict_top += ForthRAM.CELL_SIZE


func dot() -> void:
	forth.util.print_term(" " + str(forth.pop_int()))


func one_plus() -> void:
	# Add one to n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) + 1)


func one_minus() -> void:
	# Subtract one from n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) - 1)


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
	elif word in forth.built_in_address:
		forth.push_word(forth.built_in_address[word])
	else:
		forth.util.print_unknown_word(word)


func store() -> void:
	# Store x in the cell at a-addr
	# ( x a-addr - )
	var addr: int = forth.pop_word()
	forth.ram.set_word(addr, forth.pop_word())


func star() -> void:
	# Multiply n1 by n2 leaving the product n3
	# ( n1 n2 - n3 )
	var t: int = (
		forth.ram.get_int(forth.ds_p)
		* forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


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


func slash() -> void:
	# divide n1 by n2, leaving the quotient n3
	# ( n1 n2 - n3 )
	var t: int = (
		forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
		/ forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


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


func q_dup() -> void:
	# ( x - 0 | x x )
	var t: int = forth.ram.get_int(forth.ds_p)
	if t != 0:
		forth.push_word(t)


func two_star() -> void:
	# Return x2, result of shifting x1 one bit towards the MSB,
	# filling the LSB with zero
	# ( x1 - x2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) << 1)


func two_slash() -> void:
	# Return x2, result of shifting x1 one bit towards LSB,
	# leaving the MSB unchanged
	# ( x1 - x2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) >> 1)


func two_drop() -> void:
	# remove the top pair of cells from the stack
	# ( x1 x2 - )
	forth.pop_dword()


func two_dup() -> void:
	# duplicate the top cell pair
	# (x1 x2 - x1 x2 x1 x2 )
	var t: int = forth.ram.get_dword(forth.ds_p)
	forth.push_dword(t)


func two_over() -> void:
	# copy a cell pair x1 x2 to the top of the stack
	# ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
	forth.ds_p -= ForthRAM.DCELL_SIZE
	forth.ram.set_dword(
		forth.ds_p, forth.ram.get_dword(forth.ds_p + 2 * ForthRAM.DCELL_SIZE)
	)


func two_swap() -> void:
	# exchange the top two cell pairs
	# ( x1 x2 x3 x4 - x3 x4 x1 x2 )
	var t: int = forth.ram.get_dword(forth.ds_p + ForthRAM.DCELL_SIZE)
	forth.ram.set_dword(
		forth.ds_p + ForthRAM.DCELL_SIZE, forth.ram.get_dword(forth.ds_p)
	)
	forth.ram.set_dword(forth.ds_p, t)


func to_in() -> void:
	# Return address of a cell containing the offset, in characters,
	# from the start of the input buffer to the start of the current
	# parse position
	# ( - a-addr )
	forth.push_word(forth.BUFF_TO_IN)


func fetch() -> void:
	# Replace a-addr with the contents of the cell at a_addr
	# ( a_addr - x )
	forth.push_word(forth.ram.get_word(forth.pop_word()))


func cell_plus() -> void:
	# Add the size in bytes of a cell to a_addr1, returning a_addr2
	# ( a-addr1 - a-addr2 )
	forth.push_word(ForthRAM.CELL_SIZE)
	plus()


func cells() -> void:
	# Return n2, the size in bytes of n1 cells
	# ( n1 - n2 )
	forth.push_word(ForthRAM.CELL_SIZE)
	star()


func c_comma() -> void:
	# Rserve one byte of data space and store char in the byte
	# ( char - )
	forth.ram.set_byte(forth.dict_top, forth.pop_word())
	forth.dict_top += 1


func char_plus() -> void:
	# Add the size in bytes of a character to c_addr1, giving c-addr2
	# ( c-addr1 - c-addr2 )
	forth.push_word(1)
	plus()


func chars() -> void:
	# Return n2, the size in bytes of n1 characters. May be a no-op.
	pass


func constant() -> void:
	# Create a dictionary entry for name, associated with constant x.
	# ( x - )
	forth.create_dict_entry_name()
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[constant_exec]
	)
	# store the constant
	forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, forth.pop_word())
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up


func constant_exec() -> void:
	# execution time functionality of _constant
	# return contents of cell after execution token
	forth.push_word(forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE))


func count() -> void:
	# Return the length n, and address of the text portion of a counted string
	# ( c_addr1 - c_addr2 u )
	var addr: int = forth.pop_word()
	forth.push_word(addr + 1)
	forth.push_word(forth.ram.get_byte(addr))


func create() -> void:
	# Construct a dictionary entry for the next token in the input stream
	# Execution of *name* will return the address of its data space
	# ( - )
	forth.create_dict_entry_name()
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[create_exec]
	)
	forth.dict_top += ForthRAM.CELL_SIZE


func create_exec() -> void:
	# execution time functionality of create
	# return address of cell after execution token
	forth.push_word(forth.dict_ip + ForthRAM.CELL_SIZE)


func depth() -> void:
	# ( - +n )
	forth.push_word((forth.DS_TOP - forth.ds_p) / ForthRAM.CELL_SIZE)


func dup() -> void:
	# ( x - x x )
	var t: int = forth.ram.get_int(forth.ds_p)
	forth.push_word(t)


func drop() -> void:
	# ( x - )
	forth.pop_word()


func emit() -> void:
	# Output one character from the LSB of the top item on stack.
	# ( b - )
	var c: int = forth.pop_word()
	forth.util.print_term(char(c))


func execute() -> void:
	# Remove execution token xt from the stack and perform
	# the execution behavior it identifies
	# ( xt - )
	var xt: int = forth.pop_word()
	if xt in forth.built_in_function_from_address:
		# this xt identifies a gdscript function
		forth.built_in_function_from_address[xt].call()
	elif xt >= forth.DICT_START and xt < forth.DICT_TOP:
		# this is a physical address of an xt
		forth.dict_ip = xt
		# push the xt
		forth.push_word(forth.ram.get_word(xt))
		# recurse down a layer
		execute()
	else:
		forth.util.rprint_term(" Invalid execution token")


func here() -> void:
	# Return address of the next available location in data-space
	# ( - addr )
	forth.push_word(forth.dict_top)


func invert() -> void:
	# Invert all bits of x1, giving its logical inverse x2
	# ( x1 - x2 )
	forth.ram.set_word(forth.ds_p, ~forth.ram.get_word(forth.ds_p))


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


func negate() -> void:
	# Change the sign of the top stack value
	# ( n - -n )
	forth.ram.set_int(forth.ds_p, -forth.ram.get_int(forth.ds_p))


func source() -> void:
	# Return the address and length of the input buffer
	# ( - c-addr u )
	forth.push_word(forth.BUFF_SOURCE_START)
	forth.push_word(forth.BUFF_SOURCE_SIZE)


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


func f_abs() -> void:
	# Replace the top stack item with its absolute value
	# ( n - +n )
	forth.ram.set_word(forth.ds_p, abs(forth.ram.get_int(forth.ds_p)))


func allot() -> void:
	# Allocate u bytes of data space beginning at the next location.
	# ( u - )
	forth.dict_top += forth.pop_word()


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


func b_l() -> void:
	# Return char, the ASCII character value of a space
	# ( - char )
	forth.push_word(int(ForthTerminal.BL))


# gdlint:ignore = max-file-lines


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


func over() -> void:
	# place a copy of x1 on top of the stack
	# ( x1 x2 - x1 x2 x1 )
	forth.ds_p -= ForthRAM.CELL_SIZE
	forth.ram.set_int(
		forth.ds_p, forth.ram.get_int(forth.ds_p + 2 * ForthRAM.CELL_SIZE)
	)


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


func s_to_d() -> void:
	# Convert a single cell number n to its double equivalent d
	# ( n - d )
	var t: int = forth.ram.get_int(forth.ds_p)
	forth.ds_p += ForthRAM.CELL_SIZE - ForthRAM.DCELL_SIZE
	forth.ram.set_dint(forth.ds_p, t)


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


func swap() -> void:
	# exchange the top two items on the stack
	# ( x1 x2 - x2 x1 )
	var t: int = forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	forth.ram.set_int(
		forth.ds_p + ForthRAM.CELL_SIZE, forth.ram.get_int(forth.ds_p)
	)
	forth.ram.set_int(forth.ds_p, t)


func type() -> void:
	# Output the characer string at c-addr, length u
	# ( c-addr u - )
	var l: int = forth.pop_word()
	var s: int = forth.pop_word()
	for i in l:
		forth.push_word(forth.ram.get_byte(s + i))
		emit()


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


func variable() -> void:
	# Create a dictionary entry for name associated with one cell of data
	# ( - )
	forth.core.create()
	# make room for one cell
	forth.dict_top += ForthRAM.CELL_SIZE


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
