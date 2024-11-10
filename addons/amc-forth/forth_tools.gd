class_name ForthTools
## Define built-in Forth words in the TOOLS word set
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthCore.new())
##
## (1) All functions with "## @WORD <word>" comment will become
## the default implementation for the built-in word.
## (2) All functions with "## @WORDX <word>" comment will become
## the *compiled* implementation for the built-in word.
## (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
func _init(_forth: AMCForth) -> void:
	super(_forth)


## @WORD ?
func question() -> void:
	# Fetch the contents of the given address and display
	# ( a-addr - )
	forth.core.fetch()
	forth.core.dot()


## @WORD .S
func dot_s() -> void:
	var pointer = forth.DS_TOP - ForthRAM.CELL_SIZE
	var fmt:String = "%d" if forth.ram.get_word(forth.BASE) == 10 else "%x"
	forth.util.rprint_term("")
	while pointer >= forth.ds_p:
		forth.util.print_term(" " + fmt % forth.ram.get_int(pointer))
		pointer -= ForthRAM.CELL_SIZE
	forth.util.print_term(" <-Top")


## @WORD WORDS
func words() -> void:
	# List all the definition names in the word list of the search order.
	# Returns dictionary names, then built-in names.
	# ( - )
	var word_len: int
	var col: int = "WORDS".length() + 1
	forth.util.print_term(" ")
	if forth.dict_p != forth.dict_top:
		# dictionary is not empty
		var p: int = forth.dict_p
		while p != -1:
			forth.push_word(p + ForthRAM.CELL_SIZE)
			forth.core.count()  # search word in addr, n format
			forth.core.dup()  # retrieve the size
			word_len = forth.pop_word()
			if col + word_len + 1 >= ForthTerminal.COLUMNS - 2:
				forth.util.print_term(ForthTerminal.CRLF)
				col = 0
			col += word_len + 1
			# emit the dictionary entry name
			forth.core.type()
			forth.util.print_term(" ")
			# drill down to the next entry
			p = forth.ram.get_int(p)
	# now go through the built-in names
	for entry in forth.built_in_names:
		word_len = entry[0].length()
		if col + word_len + 1 >= ForthTerminal.COLUMNS - 2:
			forth.util.print_term(ForthTerminal.CRLF)
			col = 0
		col += word_len + 1
		forth.util.print_term(entry[0] + " ")
