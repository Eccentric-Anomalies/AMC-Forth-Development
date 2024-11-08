class_name ForthCoreExt

extends ForthImplementationBase

var _forth: ForthImplementationBase


func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				[".(", dot_left_parenthesis],  # core ext
				["\\", back_slash],  # core ext
				["PARSE", parse],  # core ext
			]
		)
	)


func dot_left_parenthesis() -> void:
	# Begin parsing a comment, terminated by ')'. Comment text
	# will emit to the terminal.
	# ( - )
	forth.core.start_parenthesis()
	forth.type()

func back_slash() -> void:
	# Begin parsing a comment, terminated by end of line
	# ( - )
	forth.push_word(ForthTerminal.CR.to_ascii_buffer()[0])
	forth.parse()
	forth.two_drop()

func parse() -> void:
	# Parse text to the first instance of char, returning the address
	# and length of a temporary location containing the parsed text.
	# Returns an address with one byte available in front for forming
	# a character count. Consumes the final delimiter.
	# ( char - c_addr n )
	var count: int = 0
	var ptr: int = forth.WORD_START + 1
	var delim: int = forth.pop_word()
	forth.core.source()
	var source_size: int = forth.pop_word()
	var source_start: int = forth.pop_word()
	forth.core.to_in()
	var ptraddr: int = forth.pop_word()
	forth.push_word(ptr)  # parsed text begins here
	while true:
		var t: int = forth.ram.get_byte(source_start + forth.ram.get_word(ptraddr))
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
	forth.push_word(count)
