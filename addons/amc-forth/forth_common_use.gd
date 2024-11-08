class_name ForthCommonUse

extends ForthImplementationBase


func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				["2+", two_plus],  # common use
				["2-", two_minus],  # common use
				["M-", m_minus],  # common use
				["M/", m_slash],  # common use
			]
		)
	)


func two_plus() -> void:
	# Add two to n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) + 2)


func two_minus() -> void:
	# Subtract two from n1, leaving n2
	# ( n1 - n2 )
	forth.ram.set_int(forth.ds_p, forth.ram.get_int(forth.ds_p) - 2)


func m_minus() -> void:
	# Subtract n from d1 leaving the difference d2
	# ( d1 n - d2 )
	forth.s_p += ForthRAM.CELL_SIZE
	forth.ram.set_dint(
		forth.ds_p,
		(
			forth.ram.get_dint(forth.ds_p)
			- forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)


func m_slash() -> void:
	# Divide d by n1 leaving the single precision quotient n2
	# ( d n1 - n2 )
	var t: int = (
		forth.ram.get_dint(forth.ds_p + ForthRAM.CELL_SIZE)
		/ forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.DCELL_SIZE
	forth.ram.set_int(forth.ds_p, t)
