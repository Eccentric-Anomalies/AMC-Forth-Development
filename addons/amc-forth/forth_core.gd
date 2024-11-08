class_name ForthCore

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
				[">IN", to_in],  # core
				["@", fetch],  # core
				["CELL+", cell_plus],  # core
				["CELLS", cells],  # core
				["CHAR+", char_plus],  # core
				["COUNT", count],  # core
				["DUP", dup],  # core
				["SOURCE", source],  # core
				["WORD", word],  # core
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
	var t: int = forth.ram.get_int(forth.ds_p) + forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


func minus() -> void:
	# subtract n2 from n1, leaving the diference n3
	# ( n1 n2 - n3 )
	var t: int = forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE) - forth.ram.get_int(forth.ds_p)
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
	var t: int = forth.ram.get_int(forth.ds_p) * forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE)
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_int(forth.ds_p, t)


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


func char_plus() -> void:
	# Add the size in bytes of a character to c_addr1, giving c-addr2
	# ( c-addr1 - c-addr2 )
	forth.push_word(1)
	plus()


func count() -> void:
	# Return the length n, and address of the text portion of a counted string
	# ( c_addr1 - c_addr2 u )
	var addr: int = forth.pop_word()
	forth.push_word(addr + 1)
	forth.push_word(forth.ram.get_byte(addr))


func dup() -> void:
	# ( x - x x )
	var t: int = forth.ram.get_int(forth.ds_p)
	forth.push_word(t)



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
		var t: int = forth.ram.get_byte(source_start + forth.ram.get_word(ptraddr))
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

