class_name ForthCore  # gdlint:ignore = max-public-methods
## @WORDSET Core
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
## (4) UP TO four comments beginning with "##" before function
## (5) Final comment must be "## @STACK" followed by stack def.
func _init(_forth: AMCForth) -> void:
	super(_forth)


## Utility function for parsing comments
func start_parenthesis() -> void:
	forth.push(")".to_ascii_buffer()[0])
	forth.core_ext.parse()


## @WORD (
## Begin parsing a comment, terminated by ')' character.
## @STACK ( - )
func left_parenthesis() -> void:
	start_parenthesis()
	forth.core.two_drop()


## @WORD +
## Add n1 to n2 leaving the sum n3.
## @STACK ( n1 n2 - n3 )
func plus() -> void:
	forth.push(forth.ram.truncate_to_cell(forth.pop() + forth.pop()))


## @WORD -
## Subtract n2 from n1, leaving the difference n3.
## @STACK ( n1 n2 - n3 )
func minus() -> void:
	var n: int = forth.pop()
	forth.push(forth.ram.truncate_to_cell(forth.pop() - n))


## @WORD ,
## Reserve one cell of data space and store x in it.
## @STACK ( x - )
func comma() -> void:
	forth.ram.set_int(forth.dict_top, forth.pop())
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORD .
## Display the value, x, on the top of the stack.
## @STACK ( x - )
func dot() -> void:
	var fmt: String = "%d" if forth.ram.get_int(forth.BASE) == 10 else "%x"
	forth.util.print_term(" " + fmt % forth.pop())


## @WORD ." IMMEDIATE
## Type the string when the containing word is executed.
## @STACK ( "string" - c-addr u )
func dot_quote() -> void:
	# compilation behavior
	if forth.state:
		start_string()
		# copy the execution token
		forth.ram.set_int(
			forth.dict_top,
			forth.address_from_built_in_function[dot_quote_exec]
		)
		# store the value
		var l = forth.pop()  # length of the string
		var src = forth.pop()  # first byte address
		forth.dict_top += ForthRAM.CELL_SIZE
		forth.ram.set_byte(forth.dict_top, l)  # store the length
		# compile the string into the dictionary
		for i in l:
			forth.dict_top += 1
			forth.ram.set_byte(forth.dict_top, forth.ram.get_byte(src + i))
		# this will align the dict top and save it
		align()


## @WORDX ."
func dot_quote_exec() -> void:
	var l: int = forth.ram.get_byte(forth.dict_ip + ForthRAM.CELL_SIZE)
	forth.push(forth.dict_ip + ForthRAM.CELL_SIZE + 1)  # address of the string start
	forth.push(l)  # length of the string
	# send to the terminal
	type()
	# moves to string cell for l in 0..3, then one cell past for l in 4..7, etc.
	forth.dict_ip += ((l / ForthRAM.CELL_SIZE) + 1) * ForthRAM.CELL_SIZE


## @WORD 1+
## Add one to n1, leaving n2.
## @STACK ( n1 - n2 )
func one_plus() -> void:
	forth.push(1)
	plus()


## @WORD 1-
## Subtract one from n1, leaving n2.
## @STACK ( n1 - n2 )
func one_minus() -> void:
	forth.push(1)
	minus()


## @WORD '
## Search the dictionary for <name> and leave its execution token
## on the stack. Abort if name cannot be found.
## Usage: ' <name>
## @STACK ( "name" - xt )
func tick() -> void:
	# retrieve the name token
	forth.core_ext.parse_name()
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
## Store x in the cell at a-addr.
## @STACK ( x a-addr - )
func store() -> void:
	var addr: int = forth.pop()
	forth.ram.set_int(addr, forth.pop())


## @WORD *
## Multiply n1 by n2 leaving the product n3.
## @STACK ( n1 n2 - n3 )
func star() -> void:
	forth.push(forth.ram.truncate_to_cell(forth.pop() * forth.pop()))


## @WORD */
## Multiply n1 by n2 producing a double-cell result d.
## Divide d by n3, giving the single-cell quotient n4.
## @STACK ( n1 n2 n3 - n4 )
func star_slash() -> void:
	var d: int = forth.pop()
	forth.push(forth.ram.truncate_to_cell(forth.pop() * forth.pop() / d))


## @WORD */MOD
## Multiply n1 by n2 producing a double-cell result d.
## Divide d by n3, giving the single-cell remainder n4
## and a single-cell quotient n5.
## @STACK ( n1 n2 n3 - n4 n5 )
func star_slash_mod() -> void:
	var d: int = forth.pop()
	var p: int = forth.pop() * forth.pop()
	forth.push(p % d)
	forth.push(p / d)


## @WORD /
## Divide n1 by n2, leaving the quotient n3.
## @STACK ( n1 n2 - n3 )
func slash() -> void:
	var d: int = forth.pop()
	forth.push(forth.pop() / d)


## @WORD /MOD
## Divide n1 by n2, leaving the remainder n3 and quotient n4.
## @STACK ( n1 n2 - n3 n4 )
func slash_mod() -> void:
	var div: int = forth.pop()
	var d: int = forth.pop()
	forth.push(d % div)
	forth.push(d / div)


## @WORD :
## Create a definition for <name> and enter compilation state.
## @STACK ( "name" - )
func colon() -> void:
	_smudge_address = forth.create_dict_entry_name(true)
	if _smudge_address:
		# enter compile state
		forth.state = true
		forth.ram.set_int(
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
		forth.push(forth.ram.get_int(forth.dict_ip))
		# and do what it says to do!
		execute()
	# we are exiting. reset the flag.
	forth.exit_flag = false


## @WORD ; IMMEDIATE
## Leave compilation state.
## @STACK ( - )
func semi_colon() -> void:
	# remove the smudge bit
	forth.ram.set_byte(
		_smudge_address,
		forth.ram.get_byte(_smudge_address) & ~forth.SMUDGE_BIT_MASK
	)
	# clear compile state
	forth.state = false
	# insert the XT for the semi-colon
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[semi_colon_exec]
	)
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()
	# check for control flow stack integrity
	if not forth.cf_stack_is_empty():
		forth.util.rprint_term("Unbalanced control structure")
		forth.unwind_compile()


## @WORDX ;
func semi_colon_exec() -> void:
	# Execution behavior of semi-colon
	exit()


## @WORD ?DO IMMEDIATE
## Like DO, but check for the end condition before entering the loop body.
## If satisfied, continue execution following nearest LOOP or LOOP+.
## @STACK ( n1 n2 - )
func question_do() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[question_do_exec]
	)
	# mark PREV cell as a destination for a backward branch
	forth.cf_push_dest(forth.dict_top - ForthRAM.CELL_SIZE)
	# leave link address on the control stack
	forth.cf_push_orig(forth.dict_top + ForthRAM.CELL_SIZE)
	# move up to finish
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX ?DO
func question_do_exec() -> void:
	# make a copy of the parameters
	two_dup()
	# same?
	equal()
	if forth.pop() == forth.TRUE:
		# already satisfied. remove the saved parameters
		two_drop()
		# Skip ahead to the address in the next cell
		forth.dict_ip = forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE)
	else:
		# move limit and count to return stack
		forth.core_ext.two_to_r()
		# SKip over the forward reference
		forth.dict_ip += ForthRAM.CELL_SIZE


## @WORD ?DUP
## Conditionally duplicate the top item on the stack if its value is
## non-zero.
## @STACK ( x - x | x x )
func question_dup() -> void:
	# ( x - 0 | x x )
	var n: int = forth.data_stack[forth.ds_p]
	if n != 0:
		forth.push(n)


## @WORD +LOOP IMMEDIATE
## Like LOOP but increment the index by the specified signed value n. After
## incrementing, if the index crossed the boundary between the limit - 1
## and the limit, the loop is terminated.
## @STACK ( dest orig n - )
func plus_loop() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[plus_loop_exec]
	)
	# Check for any orig links
	while not forth.lcf_is_empty():
		# destination is on top of the back link
		forth.ram.set_int(forth.lcf_pop(), forth.dict_top + ForthRAM.CELL_SIZE)
	# The link back
	forth.ram.set_int(forth.dict_top + ForthRAM.CELL_SIZE, forth.cf_pop_dest())
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up and done
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX +LOOP
func plus_loop_exec() -> void:
	# ( n - )
	# pull out the increment
	var n: int = forth.pop()
	# Move to loop params to the data stack.
	forth.core_ext.two_r_from()
	forth.push(n)
	plus()  # Increment the count
	# Duplicate them
	two_dup()
	var res: int = forth.pop()
	var limit: int = forth.pop()
	# Check for loop is finished
	if (n >= 0 and res >= limit) or (n < 0 and res < limit):
		# loop is satisfied
		# spare pair of loop parameters is not needed.
		two_drop()
		# step ahead over the branch
		forth.dict_ip += ForthRAM.CELL_SIZE
	else:
		# not satisfied, branch back. The DO or ?DO exec will push the values
		# back on the return stack
		forth.dict_ip = forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE)


## @WORD <
## Return true if and only if n1 is less than n2.
## @STACK ( n1 n2 - flag )
func less_than() -> void:
	var t: int = forth.pop()
	if t > forth.pop():
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD =
## Return true if and only if n1 is equal to n2.
## @STACK ( n1 n2 - flag )
func equal() -> void:
	var t: int = forth.pop()
	if t == forth.pop():
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD >
## Return true if and only if n1 is greater than n2
## @STACK ( n1 n2 - flag )
func greater_than() -> void:
	var t: int = forth.pop()
	if t < forth.pop():
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD 0<
## Return true if and only if n is less than zero.
## @STACK ( n - flag )
func zero_less_than() -> void:
	if forth.pop() < 0:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD 0=
## Return true if and only if n is equal to zero.
## @STACK ( n - flag )
func zero_equal() -> void:
	if forth.pop():
		forth.push(forth.FALSE)
	else:
		forth.push(forth.TRUE)


## @WORD 2*
## Return x2, result of shifting x1 one bit towards the MSB,
## filling the LSB with zero.
## @STACK ( x1 - x2 )
func two_star() -> void:
	forth.push(forth.ram.truncate_to_cell(forth.pop() << 1))


## @WORD 2/
## Return x2, result of shifting x1 one bit towards LSB,
## leaving the MSB unchanged.
## @STACK ( x1 - x2 )
func two_slash() -> void:
	var msb: int = forth.data_stack[forth.ds_p] & ForthRAM.CELL_MSB_MASK
	var n: int = forth.data_stack[forth.ds_p]
	# preserve msbit
	forth.data_stack[forth.ds_p] = (n >> 1) | msb


## @WORD 2DROP
## Remove the top pair of cells from the stack.
## @STACK ( x1 x2 - )
func two_drop() -> void:
	forth.pop()
	forth.pop()


## @WORD 2DUP
## Duplicate the top cell pair.
## @STACK (x1 x2 - x1 x2 x1 x2 )
func two_dup() -> void:
	var x2: int = forth.data_stack[forth.ds_p]
	var x1: int = forth.data_stack[forth.ds_p + 1]
	forth.push(x1)
	forth.push(x2)


## @WORD 2OVER
## Copy a cell pair x1 x2 to the top of the stack.
## @STACK ( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )
func two_over() -> void:
	var x2: int = forth.data_stack[forth.ds_p + 2]
	var x1: int = forth.data_stack[forth.ds_p + 3]
	forth.push(x1)
	forth.push(x2)


## @WORD 2SWAP
## Exchange the top two cell pairs.
## @STACK ( x1 x2 x3 x4 - x3 x4 x1 x2 )
func two_swap() -> void:
	var x2: int = forth.data_stack[forth.ds_p + 2]
	var x1: int = forth.data_stack[forth.ds_p + 3]
	forth.data_stack[forth.ds_p + 3] = forth.data_stack[forth.ds_p + 1]
	forth.data_stack[forth.ds_p + 2] = forth.data_stack[forth.ds_p]
	forth.data_stack[forth.ds_p + 1] = x1
	forth.data_stack[forth.ds_p] = x2


## @WORD >IN
## Return address of a cell containing the offset, in characters,
## from the start of the input buffer to the start of the current
## parse position.
## @STACK ( - a-addr )
func to_in() -> void:
	# terminal pointer or...
	if forth.source_id == -1:
		forth.push(forth.BUFF_TO_IN)
	# file buffer pointer
	elif forth.source_id:
		forth.push(forth.source_id + forth.FILE_BUFF_PTR_OFFSET)


## @WORD @
## Replace a-addr with the contents of the cell at a_addr.
## @STACK ( a_addr - x )
func fetch() -> void:
	forth.push(forth.ram.get_int(forth.pop()))


## @WORD [ IMMEDIATE
## Enter interpretation state.
## @STACK  ( - )
func left_bracket() -> void:
	forth.state = false


## @WORD ]
## Enter compilation state.
## @STACK ( - )
func right_bracket() -> void:
	forth.state = true


## @WORD ABS
## Replace the top stack item with its absolute value.
## @STACK ( n - +n )
func f_abs() -> void:
	forth.data_stack[forth.ds_p] = abs(forth.data_stack[forth.ds_p])


## @WORD ALIGN
## If the data-space pointer is not aligned, reserve space to align it.
## @STACK ( - )
func align() -> void:
	forth.push(forth.dict_top)
	aligned()
	forth.dict_top = forth.pop()
	# preserve dictionary state
	forth.save_dict_top()


## @WORD ALIGNED
## Return a-addr, the first aligned address greater than or equal to addr.
## @STACK ( addr - a-addr )
func aligned() -> void:
	var a: int = forth.pop()
	if a % ForthRAM.CELL_SIZE:
		a = (a / ForthRAM.CELL_SIZE + 1) * ForthRAM.CELL_SIZE
	forth.push(a)


## @WORD ALLOT
## Allocate u bytes of data space beginning at the next location.
## @STACK ( u - )
func allot() -> void:
	forth.dict_top += forth.pop()
	# preserve dictionary state
	forth.save_dict_top()


## @WORD AND
## Return x3, the bit-wise logical AND of x1 and x2.
## @STACK ( x1 x2 - x3)
func f_and() -> void:
	forth.push(forth.pop() & forth.pop())


## @WORD BASE
## Return a-addr, the address of a cell containing the current number
## conversion radix, between 2 and 36 inclusive.
## @STACK ( - a-addr )
func base() -> void:
	forth.push(forth.BASE)


## @WORD BEGIN IMMEDIATE
## Mark the destination of a backward branch.
## @STACK ( - dest )
func begin() -> void:
	# backwards by one cell, so execution will advance it to the right point
	forth.cf_push_dest(forth.dict_top - ForthRAM.CELL_SIZE)


## @WORD BL
## Return char, the ASCII character value of a space.
## @STACK ( - char )
func b_l() -> void:
	forth.push(ForthTerminal.BL.to_ascii_buffer()[0])


## @WORD CELL+
## Add the size in bytes of a cell to a_addr1, returning a_addr2.
## @STACK ( a-addr1 - a-addr2 )
func cell_plus() -> void:
	forth.push(ForthRAM.CELL_SIZE)
	plus()


## @WORD CELLS
## Return n2, the size in bytes of n1 cells.
## @STACK ( n1 - n2 )
func cells() -> void:
	forth.push(ForthRAM.CELL_SIZE)
	star()


## @WORD C,
## Reserve one byte of data space and store char in the byte.
## @STACK ( char - )
func c_comma() -> void:
	forth.ram.set_byte(forth.dict_top, forth.pop())
	forth.dict_top += 1
	# preserve dictionary state
	forth.save_dict_top()


## @WORD CHAR+
## Add the size in bytes of a character to c_addr1, giving c-addr2.
## @STACK ( c-addr1 - c-addr2 )
func char_plus() -> void:
	forth.push(1)
	plus()


## @WORD CHARS
## Return n2, the size in bytes of n1 characters. May be a no-op.
## @STACK ( n1 - n2 )
func chars() -> void:
	pass


## @WORD CONSTANT
## Create a dictionary entry for <name>, associated with constant x.
## Executing <name> places the value on the stack.
## Usage: <x> CONSTANT <name>
## @STACK Compile: ( "name" x - ), Execute: ( - x )
func constant() -> void:
	var init_val: int = forth.pop()
	if forth.create_dict_entry_name():
		# copy the execution token
		forth.ram.set_int(
			forth.dict_top, forth.address_from_built_in_function[constant_exec]
		)
		# store the constant
		forth.ram.set_int(forth.dict_top + ForthRAM.CELL_SIZE, init_val)
		forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
		# preserve dictionary state
		forth.save_dict_top()


## @WORDX CONSTANT
func constant_exec() -> void:
	# execution time functionality of _constant
	# return contents of cell after execution token
	forth.push(forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE))


## @WORD COUNT
## Return the length u, and address of the text portion of a counted string.
## @STACK ( c_addr1 - c_addr2 u )
func count() -> void:
	var addr: int = forth.pop()
	forth.push(addr + 1)
	forth.push(forth.ram.get_byte(addr))


## @WORD CR
## Emit characters to generate a newline on the terminal.
## @STACK ( - )
func c_r() -> void:
	forth.util.print_term(ForthTerminal.CRLF)


## @WORD CREATE
## Construct a dictionary entry for the next token <name> in the input stream.
## Execution of <name> will return the address of its data space.
## @STACK Compile: ( "name" - ), Execute: ( - addr )
func create() -> void:
	if forth.create_dict_entry_name():
		forth.ram.set_int(
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
## Sets BASE to 10.
## @STACK ( - )
func decimal() -> void:
	forth.push(10)
	base()
	store()


## @WORD DEPTH
## Return the number of single-cell values on the stack before execution.
## @STACK ( - +n )
func depth() -> void:
	# ( - +n )
	forth.push(forth.DATA_STACK_SIZE - forth.ds_p)


## @WORD DO IMMEDIATE
## Establish loop parameters, initial index n2 on the top of stack,
## with the limit value n1 below it. These are transferred to the
## return stack when DO is executed.
## @STACK ( n1 n2 - )
func do() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[do_exec]
	)
	# mark a destination for a backward branch
	begin()
	# move up to finish
	forth.dict_top += ForthRAM.CELL_SIZE  # one cell up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX DO
func do_exec() -> void:
	# push limit, then count on return stack
	forth.core_ext.two_to_r()


## @WORD DUP
## Duplicate the top entry on the stack.
## @STACK ( x - x x )
func dup() -> void:
	forth.push(forth.data_stack[forth.ds_p])


## @WORD DROP
## Drop (remove) the top entry of the stack.
## @STACK ( x - )
func drop() -> void:
	forth.pop()


## @WORD ELSE IMMEDIATE
## At compile time, originate the TRUE branch and and resolve the FALSE.
## @STACK ( - )
func f_else() -> void:
	forth.tools_ext.ahead()
	forth.cf_stack_roll(1)
	f_then()


## @WORD EMIT
## Output one character from the LS byte of the top item on stack.
## @STACK ( b - )
func emit() -> void:
	var c: int = forth.pop()
	forth.util.print_term(char(c))


## @WORD EVALUATE
## Use c-addr, u as the buffer start and interpret as Forth source.
## @STACK ( i*x c-addr u - j*x )
func evaluate() -> void:
	var base: int = forth.ram.get_int(forth.BASE)
	# we can discard the buffer location, since we use the source_id
	# to identify the buffer
	forth.pop()
	forth.pop()
	# buffer pointer is based on source-id
	forth.reset_buff_to_in()
	while true:
		# call the Forth WORD, setting blank as delimiter
		forth.core_ext.parse_name()
		var len: int = forth.pop()  # length of word
		var caddr: int = forth.pop()  # start of word
		# out of tokens?
		if len == 0:
			break
		var t: String = forth.util.str_from_addr_n(caddr, len)
		# t should be the next token, try to get an execution token from it
		var xt_immediate = forth.find_in_dict(t)
		if not xt_immediate[0] and t.to_upper() in forth.built_in_function:
			xt_immediate = [forth.xt_from_word(t.to_upper()), false]
		# an execution token exists
		if xt_immediate[0] != 0:
			forth.push(xt_immediate[0])
			# check if it is a built-in immediate or dictionary immediate before storing
			if forth.state and not (forth.is_immediate(t) or xt_immediate[1]):  # Compiling
				forth.core.comma()  # store at the top of the current : definition
			else:  # Not Compiling or immediate - just execute
				forth.core.execute()
		# no valid token, so maybe valid numeric value (double first)
		elif t.contains(".") and forth.is_valid_int(t.replace(".", ""), base):
			var t_strip: String = t.replace(".", "")
			var temp: int = forth.to_int(t_strip, base)
			forth.push_dword(temp)
			# compile it, if necessary
			if forth.state:
				forth.double.two_literal()
		elif forth.is_valid_int(t, base):
			var temp: int = forth.to_int(t, base)
			# single-precision
			forth.push(temp)
			# compile it, if necessary
			if forth.state:
				literal()
		# nothing we recognize
		else:
			forth.util.print_unknown_word(t)
			# do some clean up if we were compiling
			forth.unwind_compile()
			break  # not ok
		# check the stack
		if forth.ds_p < 0:
			forth.util.rprint_term(" Data stack overflow")
			forth.ds_p = AMCForth.DATA_STACK_SIZE
			break  # not ok
		if forth.ds_p > AMCForth.DATA_STACK_SIZE:
			forth.util.rprint_term(" Data stack underflow")
			forth.ds_p = AMCForth.DATA_STACK_SIZE
			break  # not ok


## @WORD EXECUTE
## Remove execution token xt from the stack and perform
## the execution behavior it identifies.
## @STACK ( xt - )
func execute() -> void:
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
		forth.push(forth.ram.get_int(xt))
		# recurse down a layer
		execute()
		# restore our ip
		forth.pop_ip()
	else:
		forth.util.rprint_term(" Invalid execution token")


## @WORD EXIT
## Return control to the calling definition in the ip-stack.
## @STACK ( - )
func exit() -> void:
	# set a flag indicating exit has been called
	forth.exit_flag = true


## @WORD HERE
## Return address of the next available location in data-space.
## @STACK ( - addr )
func here() -> void:
	forth.push(forth.dict_top)


## @WORD I
## Push a copy of the current DO-LOOP index value to the stack.
## @STACK ( - n )
func i() -> void:
	r_fetch()


## @WORD IF IMMEDIATE
## Place forward reference origin on the control flow stack.
## @STACK ( - orig )
func f_if() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[f_if_exec]
	)
	# leave link address on the control stack
	forth.cf_push_orig(forth.dict_top + ForthRAM.CELL_SIZE)
	# move up to finish
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX IF
func f_if_exec() -> void:
	# Branch to ELSE if top of stack not TRUE
	# ( x - )
	if forth.pop() == 0:
		forth.dict_ip = forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE)
	else:
		# TRUE, so skip over the link and continue executing
		forth.dict_ip += ForthRAM.CELL_SIZE


## @WORD IMMEDIATE
## Make the most recent definition (top of the dictionary) an IMMEDIATE word.
## @STACK ( - )
func immediate() -> void:
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
## Invert all bits of x1, giving its logical inverse, x2.
## @STACK ( x1 - x2 )
func invert() -> void:
	forth.data_stack[forth.ds_p] = ~forth.data_stack[forth.ds_p]


## @WORD J
## Push a copy of the next-outer DO-LOOP index value to the stack.
## @STACK ( - n )
func j() -> void:
	# reach up into the return stack for the value
	forth.push(forth.return_stack[forth.rs_p + 2])


## @WORD LEAVE IMMEDIATE
## Discard loop parameters and continue execution immediately following
## the next LOOP or LOOP+ containing this LEAVE.
## @STACK ( - )
func leave() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[leave_exec]
	)
	# leave a special LEAVE link address on the leave control stack
	forth.lcf_push(forth.dict_top + ForthRAM.CELL_SIZE)
	# move up to finish
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX LEAVE
func leave_exec() -> void:
	# Discard loop parameters
	forth.r_pop()
	forth.r_pop()
	# Skip ahead to the LOOP address in the next cell
	forth.dict_ip = forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE)


## @WORD LITERAL IMMEDIATE
## At execution time, remove the top number from the stack and compile
## into the current definition. Upon executing <name>, place the
## number on the top of the stack.
## @STACK Compile:  ( x - ), Execute: ( - x )
func literal() -> void:
	var literal_val: int = forth.pop()
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[literal_exec]
	)
	# store the value
	forth.ram.set_int(forth.dict_top + ForthRAM.CELL_SIZE, literal_val)
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX LITERAL
func literal_exec() -> void:
	# execution time functionality of literal
	# return contents of cell after execution token
	forth.push(forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE))
	# advance the instruction pointer by one to skip over the data
	forth.dict_ip += ForthRAM.CELL_SIZE


## @WORD LSHIFT
## Perform a logical left shift of u places on x1, giving x2.
## Fill the vacated LSB bits with zero.
## @STACK (x1 u - x2 )
func lshift() -> void:
	swap()
	forth.push(forth.ram.truncate_to_cell(forth.pop() << forth.pop()))


## @WORD LOOP IMMEDIATE
## Increment the index value by one and compare to the limit value.
## If they are equal, continue with the next instruction, otherwise
## return to the address of the preceding DO.
## @STACK ( dest orig - )
func loop() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[loop_exec]
	)
	# Check for any orig links
	while not forth.lcf_is_empty():
		# destination is on top of the back link
		forth.ram.set_int(forth.lcf_pop(), forth.dict_top + ForthRAM.CELL_SIZE)
	# The link back
	forth.ram.set_int(forth.dict_top + ForthRAM.CELL_SIZE, forth.cf_pop_dest())
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up and done
	# preserve dictionary state
	forth.save_dict_top()


## @WORDX LOOP
func loop_exec() -> void:
	# Move to data stack.
	forth.core_ext.two_r_from()
	# Increment the count
	one_plus()
	# Duplicate them
	two_dup()
	# Check for equal
	equal()
	if forth.pop() == 0:
		# not matched, branch back. The DO exec will push the values
		# back on the return stack.
		forth.dict_ip = forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE)
	else:
		# spare pair of loop parameters is not needed.
		two_drop()
		# step ahead over the branch
		forth.dict_ip += ForthRAM.CELL_SIZE


## @WORD M*
## Multiply n1 by n2, leaving the double result d.
## @STACK ( n1 n2 - d )
func m_star() -> void:
	forth.push_dint(forth.pop() * forth.pop())


## @WORD MAX
## Return n3, the greater of n1 and n2.
## @STACK ( n1 n2 - n3 )
func max() -> void:
	var n2: int = forth.pop()
	if n2 > forth.data_stack[forth.ds_p]:
		forth.data_stack[forth.ds_p] = n2


## @WORD MIN
## Return n3, the lesser of n1 and n2.
## @STACK ( n1 n2 - n3 )
func min() -> void:
	var n2: int = forth.pop()
	if n2 < forth.data_stack[forth.ds_p]:
		forth.data_stack[forth.ds_p] = n2


## @WORD MOD
## Divide n1 by n2, giving the remainder n3.
## @STACK (n1 n2 - n3 )
func mod() -> void:
	var n2: int = forth.pop()
	forth.push(forth.pop() % n2)


## @WORD MOVE
## Copy u byes from a source starting at addr1, to the destination
## starting at addr2. This works even if the ranges overlap.
## @STACK ( addr1 addr2 u - )
func move() -> void:
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
## Change the sign of the top stack value.
## @STACK ( n - -n )
func negate() -> void:
	forth.data_stack[forth.ds_p] = -forth.data_stack[forth.ds_p]


## @WORD OR
## Return x3, the bit-wise inclusive or of x1 with x2.
## @STACK ( x1 x2 - x3 )
func f_or() -> void:
	forth.push(forth.pop() | forth.pop())


## @WORD OVER
## Place a copy of x1 on top of the stack.
## @STACK ( x1 x2 - x1 x2 x1 )
func over() -> void:
	forth.push(forth.data_stack[forth.ds_p + 1])


## @WORD POSTPONE IMMEDIATE
## At compile time, add the compilation behavior of the following
## name, rather than its execution behavior.
## @STACK ( "name" - )
func postpone() -> void:
	# parse for the next token
	forth.core_ext.parse_name()
	var len: int = forth.pop()  # length
	var caddr: int = forth.pop()  # start
	var word: String = forth.util.str_from_addr_n(caddr, len)
	# obtain and push the compiled xt for this word
	forth.push(forth.xtx_from_word(word))
	# then store it in the current definition
	comma()


## @WORD R@
## Place a copy of the item on top of the return stack onto the data stack.
## @STACK (S: - x ) (R: x - x )
func r_fetch() -> void:
	var t: int = forth.r_pop()
	forth.push(t)
	forth.r_push(t)


## @WORD ROT
## Rotate the top three items on the stack.
## @STACK ( x1 x2 x3 - x2 x3 x1 )
func rot() -> void:
	var t: int = forth.data_stack[forth.ds_p + 2]
	forth.data_stack[forth.ds_p + 2] = forth.data_stack[forth.ds_p + 1]
	forth.data_stack[forth.ds_p + 1] = forth.data_stack[forth.ds_p]
	forth.data_stack[forth.ds_p] = t


## @WORD RSHIFT
## Perform a logical right shift of u places on x1, giving x2.
## Fill the vacated MSB bits with zeros.
## @STACK ( x1 u - x2 )
func rshift() -> void:
	var u: int = forth.pop()
	forth.data_stack[forth.ds_p] = (
		(forth.data_stack[forth.ds_p] >> u) & ~ForthRAM.CELL_MAX_NEGATIVE
	)


## Utility function for parsing strings
func start_string() -> void:
	forth.push('"'.to_ascii_buffer()[0])
	forth.core_ext.parse()


## @WORD S" IMMEDIATE
## Return the address and length of the following string, terminated by ",
## which is in a temporary buffer.
## @STACK ( "string" - c-addr u )
func s_quote() -> void:
	start_string()
	var l = forth.pop()  # length of the string
	var src = forth.pop()  # first byte address
	# different compilation behavior
	if forth.state:
		# copy the execution token
		forth.ram.set_int(
			forth.dict_top, forth.address_from_built_in_function[s_quote_exec]
		)
		# store the value
		forth.dict_top += ForthRAM.CELL_SIZE
		forth.ram.set_byte(forth.dict_top, l)  # store the length
		# compile the string into the dictionary
		for i in l:
			forth.dict_top += 1
			forth.ram.set_byte(forth.dict_top, forth.ram.get_byte(src + i))
		# this will align the dict top and save it
		align()
	else:
		# just copy it at the end of the dictionary as a temporary area
		for i in l:
			forth.ram.set_byte(forth.dict_top + i, forth.ram.get_byte(src + i))
		# push the return values back on
		forth.push(forth.dict_top)
		forth.push(l)


## @WORDX S"
func s_quote_exec() -> void:
	var l: int = forth.ram.get_byte(forth.dict_ip + ForthRAM.CELL_SIZE)
	forth.push(forth.dict_ip + ForthRAM.CELL_SIZE + 1)  # address of the string start
	forth.push(l)  # length of the string
	# moves to string cell for l in 0..3, then one cell past for l in 4..7, etc.
	forth.dict_ip += ((l / ForthRAM.CELL_SIZE) + 1) * ForthRAM.CELL_SIZE


## @WORD S>D
## Convert a single cell number n to its double equivalent d
## @STACK ( n - d )
func s_to_d() -> void:
	forth.push_dint(forth.pop())


## @WORD SM/REM
## Divide d by n1, using symmetric division, giving quotient n3 and
## remainder n2. All arguments are signed.
## @STACK ( d n1 - n2 n3 )
func sm_slash_rem() -> void:
	var n1: int = forth.pop()
	var d: int = forth.pop_dint()
	forth.push(d % n1)
	forth.push(d / n1)


## @WORD SOURCE
## Return the address and length of the input buffer.
## @STACK ( - c-addr u )
func source() -> void:
	if forth.source_id == -1:
		forth.push(forth.BUFF_SOURCE_START)
		forth.push(forth.BUFF_SOURCE_SIZE)
	elif forth.source_id:
		forth.push(forth.source_id + forth.FILE_BUFF_DATA_OFFSET)
		forth.push(forth.FILE_BUFF_DATA_SIZE)


## @WORD SPACE
## Display one space on the current output device.
## @STACK ( - )
func space() -> void:
	forth.util.print_term(ForthTerminal.BL)


## @WORD SPACES
## Display u spaces on the current output device.
## @STACK ( u - )
func spaces() -> void:
	for i in forth.pop():
		forth.util.print_term(ForthTerminal.BL)


## @WORD SWAP
## Exchange the top two items on the stack.
## @STACK ( x1 x2 - x2 x1 )
func swap() -> void:
	var x1: int = forth.data_stack[forth.ds_p + 1]
	forth.data_stack[forth.ds_p + 1] = forth.data_stack[forth.ds_p]
	forth.data_stack[forth.ds_p] = x1


## @WORD THEN IMMEDIATE
## Place a reference to the this address at the address on the cf stack.
## @STACK ( orig - )
func f_then() -> void:
	# Note: this only places the forward reference to the position
	# just before this (the caller will step to the next location).
	# No f_then_exec function is needed.
	forth.ram.set_int(forth.cf_pop_orig(), forth.dict_top - ForthRAM.CELL_SIZE)


## @WORD U<
## Return true if and only if u1 is less than u2.
## @STACK ( u1 u2 - flag )
func u_less_than() -> void:
	var u2: int = forth.ram.unsigned(forth.pop())
	if forth.ram.unsigned(forth.pop()) < u2:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD UNLOOP
## Discard the loop parameters for the current nesting level.
## @STACK ( - )
func unloop() -> void:
	forth.r_pop_dint()


## @WORD UNTIL IMMEDIATE
## Conditionally branch back to the point immediately following
## the nearest previous BEGIN.
## @STACK ( dest x - )
func until() -> void:
	# copy the execution token
	forth.ram.set_int(
		forth.dict_top, forth.address_from_built_in_function[until_exec]
	)
	# The link back
	forth.ram.set_int(forth.dict_top + ForthRAM.CELL_SIZE, forth.cf_pop_dest())
	forth.dict_top += ForthRAM.DCELL_SIZE  # two cells up and done


## @WORDX UNTIL
func until_exec() -> void:
	# ( x - )
	# Conditional branch
	if forth.pop() == 0:
		forth.dict_ip = forth.ram.get_int(forth.dict_ip + ForthRAM.CELL_SIZE)
	else:
		# TRUE, so skip over the link and continue executing
		forth.dict_ip += ForthRAM.CELL_SIZE


## @WORD WORD
## Skip leading occurrences of the delimiter char. Parse text
## delimited by char. Return the address of a temporary location
## containing the passed text as a counted string.
## @STACK ( char - c-addr )
func word() -> void:
	dup()
	var delim: int = forth.pop()
	source()
	var source_size: int = forth.pop()
	var source_start: int = forth.pop()
	to_in()
	var ptraddr: int = forth.pop()
	while true:
		var t: int = forth.ram.get_byte(
			source_start + forth.ram.get_int(ptraddr)
		)
		if t == delim:
			# increment the input pointer
			forth.ram.set_int(ptraddr, forth.ram.get_int(ptraddr) + 1)
		else:
			break
	forth.core_ext.parse()
	var count: int = forth.pop()
	var straddr: int = forth.pop()
	var ret: int = straddr - 1
	forth.ram.set_byte(ret, count)
	forth.push(ret)


## @WORD TYPE
## Output the character string at c-addr, length u.
## @STACK ( c-addr u - )
func type() -> void:
	var l: int = forth.pop()
	var s: int = forth.pop()
	for i in l:
		forth.push(forth.ram.get_byte(s + i))
		emit()


## @WORD UM*
## Multiply u1 by u2, leaving the double-precision result ud
## @STACK ( u1 u2 - ud )
func um_star() -> void:
	forth.push_dword(
		(
			(forth.pop() & ~ForthRAM.CELL_MAX_NEGATIVE)
			* (forth.pop() & ~ForthRAM.CELL_MAX_NEGATIVE)
		)
	)


## @WORD UM/MOD
## Divide ud by n1, leaving quotient n3 and remainder n2.
## All arguments and result are unsigned.
## @STACK ( d u1 - u2 u3 )
func um_slash_mod() -> void:
	var u1: int = forth.pop() & ~ForthRAM.CELL_MAX_NEGATIVE
	# there is no gdscript way of treating this as unsigned
	var d: int = forth.pop_dword()
	forth.push(d % u1)
	forth.push(d / u1)


## @WORD VARIABLE
## Create a dictionary entry for name associated with one cell of data.
## Executing <name> returns the address of the allocated cell.
## @STACK Compile: ( "name" - ), Execute: ( - addr )
func variable() -> void:
	forth.core.create()
	# make room for one cell
	forth.dict_top += ForthRAM.CELL_SIZE
	# preserve dictionary state
	forth.save_dict_top()


## @WORD XOR
## Return x3, the bit-wise exclusive or of x1 with x2.
## @STACK ( x1 x2 - x3 )
func xor() -> void:
	forth.push(forth.pop() ^ forth.pop())

# gdlint:ignore = max-file-lines
