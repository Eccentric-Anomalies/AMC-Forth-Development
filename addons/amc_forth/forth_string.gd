class_name ForthString

extends ForthImplementationBase
## @WORDSET String
##


## Initialize (executed automatically by ForthString.new())
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


## @WORD CMOVE
## Copy u characters from addr1 to addr2. The copy proceeds from
## LOWER to HIGHER addresses.
## @STACK ( addr1 addr2 u - )
func c_move() -> void:
	var u: int = forth.pop()
	var a2: int = forth.pop()
	var a1: int = forth.pop()
	var i: int = 0
	# move in ascending order a1 -> a2, fast, then slow
	while i < u:
		if u - i >= ForthRAM.DCELL_SIZE:
			forth.ram.set_dword(a2 + i, forth.ram.get_dword(a1 + i))
			i += ForthRAM.DCELL_SIZE
		else:
			forth.ram.set_byte(a2 + i, forth.ram.get_byte(a1 + i))
			i += 1


## @WORD CMOVE>
## Copy u characters from addr1 to addr2. The copy proceeds from
## HIGHER to LOWER addresses.
## @STACK ( addr1 addr2 u - )
func c_move_up() -> void:
	var u: int = forth.pop()
	var a2: int = forth.pop()
	var a1: int = forth.pop()
	var i: int = u
	# move in descending order a1 -> a2, fast, then slow
	while i > 0:
		if i >= ForthRAM.DCELL_SIZE:
			i -= ForthRAM.DCELL_SIZE
			forth.ram.set_dword(a2 + i, forth.ram.get_dword(a1 + i))
		else:
			i -= 1
			forth.ram.set_byte(a2 + i, forth.ram.get_byte(a1 + i))


## @WORD COMPARE
## Compare string to string (see details in Forth docs).
## @STACK ( c-addr1 u1 c-addr2 u2 - n )
func compare() -> void:
	var n2: int = forth.pop()
	var a2: int = forth.pop()
	var n1: int = forth.pop()
	var a1: int = forth.pop()
	var s2: String = forth.util.str_from_addr_n(a2, n2)
	var s1: String = forth.util.str_from_addr_n(a1, n1)
	var ret: int = 0
	if s1 == s2:
		forth.push(ret)
	elif s1 < s2:
		forth.push(-1)
	else:
		forth.push(1)
