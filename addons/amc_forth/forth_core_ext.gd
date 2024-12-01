class_name ForthCoreExt  # gdlint:ignore = max-public-methods
## @WORDSET Core Extended
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthCoreExt.new())
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


## @WORD .(
## Begin parsing a comment, terminated by ')'. Comment text
## will emit to the terminal when it is compiled.
## @STACK ( - )
func dot_left_parenthesis() -> void:
	forth.core.start_parenthesis()
	forth.type()


## @WORD \
## Begin parsing a comment, terminated by end of line.
## @STACK ( - )
func back_slash() -> void:
	forth.push(ForthTerminal.CR.to_ascii_buffer()[0])
	parse()
	forth.core.two_drop()


## @WORD <>
## Return true if and only if n1 is not equal to n2.
## @STACK (	n1 n2 - flag )
func not_equal() -> void:
	var t: int = forth.pop()
	if t != forth.pop():
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD 0<>
## Return true if and only if n is not equal to zero.
## @STACK ( n - flag )
func zero_not_equal() -> void:
	if forth.pop():
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD 0>
## Return true if and only if n is greater than zero.
## @STACK ( n - flag )
func zero_greater_than() -> void:
	if forth.pop() > 0:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD 2>R
## Pop the top two cells from the data stack and push them onto the
## return stack.
## @STACK (S: x1 x2 - )  (R: - x1 x2 )
func two_to_r() -> void:
	forth.r_push_dint(forth.pop_dint())


## @WORD 2R>
## Pop the top two cells from the return stack and push them onto the
## data stack.
## @STACK (S: - x1 x2 )  (R: x1 x2 - )
func two_r_from() -> void:
	forth.push_dint(forth.r_pop_dint())


## @WORD 2R@
## Push a copy of the top two return stack cells onto the data stack.
## @STACK (S: - x1 x2 ) (R: x1 x2 - x1 x2 )
func two_r_fetch() -> void:
	var t: int = forth.r_pop_dint()
	forth.push_dint(t)
	forth.r_push_dint(t)


## @WORD >R
## Remove the item on top of the data stack and put it on the return stack.
## @STACK (S: x - ) (R: - x )
func to_r() -> void:
	forth.r_push(forth.pop())


## @WORD R>
## Remove the item on the top of the return stack and put it on the data stack.
## @STACK (S: - x ) (R: x - )
func r_from() -> void:
	forth.push(forth.r_pop())


## @WORD AGAIN IMMEDIATE
## Unconditionally branch back to the point immediately following
## the nearest previous BEGIN.
## @STACK ( - )
func again() -> void:
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


## @WORD BUFFER:
## Create a dictionary entry for <name>, associated with n bytes of space.
## Usage: <n> BUFFER: <name>
## Executing <name> will return address of the starting byte on the stack.
## @STACK ( "name" n - )
func buffer_colon() -> void:
	forth.core.create()
	forth.core.allot()


## @WORD C" IMMEDIATE
## Return the counted-string address of the string, terminated by ",
## which is in a temporary buffer. For compilation only
## @STACK ( "string" - c-addr )
func c_quote() -> void:
	forth.core.start_string()
	# compilation behavior
	if forth.state:
		# copy the execution token
		forth.ram.set_word(
			forth.dict_top, forth.address_from_built_in_function[c_quote_exec]
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
		forth.core.align()


## @WORDX C"
func c_quote_exec() -> void:
	var l: int = forth.ram.get_byte(forth.dict_ip + ForthRAM.CELL_SIZE)
	forth.push(forth.dict_ip + ForthRAM.CELL_SIZE)  # address of the string start
	# moves to string cell for l in 0..3, then one cell past for l in 4..7, etc.
	forth.dict_ip += ((l / ForthRAM.CELL_SIZE) + 1) * ForthRAM.CELL_SIZE


## @WORD HEX
## Sets BASE to 16.
## @STACK ( - )
func hex() -> void:
	forth.push(16)
	forth.core.base()
	forth.core.store()


## @WORD FALSE
## Return a false value: a single-cell with all bits clear.
## @STACK ( - flag )
func f_false() -> void:
	forth.push(forth.FALSE)


## @WORD MARKER
## Create a dictionary definition for <name>, to be used as a deletion
## boundary. When <name> is executed, remove the definition for <name>
## and all subsequent definitions. Usage: MARKER <name>
## @STACK ( "name" - )
func marker() -> void:
	if forth.create_dict_entry_name():
		# copy the execution token
		forth.ram.set_word(
			forth.dict_top, forth.address_from_built_in_function[marker_exec]
		)
		# store the dict_p value in the next cell
		forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, forth.dict_p)
		forth.dict_top += ForthRAM.DCELL_SIZE
		# preserve the state
		forth.save_dict_top()


## @WORDX MARKER
func marker_exec() -> void:
	# execution time functionality of marker
	# set dict_p to the previous entry
	forth.dict_top = forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE)
	forth.dict_p = forth.ram.get_word(forth.dict_top)
	forth.save_dict_top()
	forth.save_dict_p()


## @WORD NIP
## Drop second stack item, leaving top unchanged.
## @STACK ( x1 x2 - x2 )
func nip() -> void:
	forth.core.swap()
	forth.core.drop()


## @WORD PARSE
## Parse text to the first instance of char, returning the address
## and length of a temporary location containing the parsed text.
## Returns a counted string. Consumes the final delimiter.
## @STACK ( char - c_addr n )
func parse() -> void:
	var count: int = 0
	var ptr: int = forth.WORD_START + 1
	var delim: int = forth.pop()
	forth.core.source()
	var source_size: int = forth.pop()
	var source_start: int = forth.pop()
	forth.core.to_in()
	var ptraddr: int = forth.pop()
	forth.push(ptr)  # parsed text begins here
	while true:
		var t: int = forth.ram.get_byte(
			source_start + forth.ram.get_word(ptraddr)
		)
		# increment the input pointer
		if t != 0:
			forth.ram.set_word(ptraddr, forth.ram.get_word(ptraddr) + 1)
		# a null character also stops the parse
		if t != 0 and t != delim:
			forth.ram.set_byte(ptr, t)
			ptr += 1
			count += 1
		else:
			break
	forth.push(count)


## @WORD PARSE-NAME
## Skip leading delimiters and parse <name> delimited by a space. Return the
## address and length of the found name.
## @STACK ( "name" - c-addr u )
func parse_name() -> void:
	forth.push(ForthTerminal.BL.to_ascii_buffer()[0])
	forth.core.word()
	forth.core.count()


## @WORD PICK
## Place a copy of the nth stack entry on top of the stack.
## The zeroth item is the top of the stack, so 0 pick is dup.
## @STACK ( +n - x )
func pick() -> void:
	var n = forth.pop()
	if n >= forth.data_stack.size():
		forth.util.rprint_term(" PICK outside data stack")
	else:
		forth.push(forth.data_stack[-n - 1])


## @WORD SOURCE-ID
## Return a value indicating current input source.
## Value is 0 for default user input, -1 for character string.
## @STACK ( - n )
func source_id() -> void:
	forth.push(forth.source_id)


## @WORD TO
## Store x in the data space associated with name (defined with VALUE).
## Usage: <x> TO <name>
## @STACK ( "name" x - )
func to() -> void:
	# get the name
	parse_name()
	var len: int = forth.pop()  # length
	var caddr: int = forth.pop()  # start
	var word: String = forth.util.str_from_addr_n(caddr, len)
	var token_addr_immediate = forth.find_in_dict(word)
	if not token_addr_immediate[0]:
		forth.util.print_unknown_word(word)
	else:
		# adjust to data field location
		forth.ram.set_word(
			token_addr_immediate[0] + ForthRAM.CELL_SIZE, forth.pop()
		)


## @WORD TRUE
## Return a true value, a single-cell value with all bits set.
## @STACK ( - flag )
func f_true() -> void:
	forth.push(forth.TRUE)


## @WORD TUCK
## Place a copy of the top stack item below the second stack item.
## @STACK ( x1 x2 - x2 x1 x2 )
func tuck() -> void:
	forth.core.swap()
	forth.push(forth.data_stack[forth.ds_p + 1])


## @WORD U>
## Return true if and only if u1 is greater than u2.
## @STACK ( u1 u2 - flag )
func u_less_than() -> void:
	var u2: int = forth.ram.unsigned(forth.pop())
	if forth.ram.unsigned(forth.pop()) > u2:
		forth.push(forth.TRUE)
	else:
		forth.push(forth.FALSE)


## @WORD UNUSED
## Return u, the number of bytes remaining in the memory area
## where dictionary entries are constructed.
## @STACK ( - u )
func unused() -> void:
	forth.push(forth.DICT_TOP - forth.dict_top)


## @WORD VALUE
## Create a dictionary entry for name, associated with value x.
## Usage: <x> VALUE <name>
## @STACK ( "name" x - )
func value() -> void:
	var init_val: int = forth.pop()
	if forth.create_dict_entry_name():
		# copy the execution token
		forth.ram.set_word(
			forth.dict_top, forth.address_from_built_in_function[value_exec]
		)
		# store the initial value
		forth.ram.set_word(forth.dict_top + ForthRAM.CELL_SIZE, init_val)
		forth.dict_top += ForthRAM.DCELL_SIZE
		# preserve the state
		forth.save_dict_top()


## @WORDX VALUE
func value_exec() -> void:
	# execution time functionality of value
	# return contents of the cell after the execution token
	forth.push(forth.ram.get_word(forth.dict_ip + ForthRAM.CELL_SIZE))
