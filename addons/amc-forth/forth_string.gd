class_name ForthString

extends ForthImplementationBase


func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				["CMOVE", c_move],  # string
				["CMOVE>", c_move_up],  # string
				["COMPARE", compare],  # string
			]
		)
	)


func c_move() -> void:
	# Copy u characters from addr1 to addr2. The copy proceeds from
	# LOWER to HIGHER addresses.
	# ( addr1 addr2 u - )
	var u: int = forth.pop_word()
	var a2: int = forth.pop_word()
	var a1: int = forth.pop_word()
	var i: int = 0
	# move in ascending order a1 -> a2, fast, then slow
	while i < u:
		if u - i >= ForthRAM.DCELL_SIZE:
			forth.ram.set_dword(a2 + i, forth.ram.get_dword(a1 + i))
			i += ForthRAM.DCELL_SIZE
		else:
			forth.ram.set_byte(a2 + i, forth.ram.get_byte(a1 + i))
			i += 1


func c_move_up() -> void:
	# Copy u characters from addr1 to addr2. The copy proceeds from
	# HIGHER to LOWER addresses.
	# ( addr1 addr2 u - )
	var u: int = forth.pop_word()
	var a2: int = forth.pop_word()
	var a1: int = forth.pop_word()
	var i: int = u
	# move in descending order a1 -> a2, fast, then slow
	while i > 0:
		if i >= ForthRAM.DCELL_SIZE:
			i -= ForthRAM.DCELL_SIZE
			forth.ram.set_dword(a2 + i, forth.ram.get_dword(a1 + i))
		else:
			i -= 1
			forth.ram.set_byte(a2 + i, forth.ram.get_byte(a1 + i))


func compare() -> void:
	# Compare string to string (see details in docs)
	# ( c-addr1 u1 c-addr2 u2 - n )
	var n2: int = forth.pop_word()
	var a2: int = forth.pop_word()
	var n1: int = forth.pop_word()
	var a1: int = forth.pop_word()
	var s2: String = forth.util.str_from_addr_n(a2, n2)
	var s1: String = forth.util.str_from_addr_n(a1, n1)
	var ret: int = 0
	if s1 == s2:
		forth.push_word(ret)
	elif s1 < s2:
		forth.push_word(-1)
	else:
		forth.push_word(1)
