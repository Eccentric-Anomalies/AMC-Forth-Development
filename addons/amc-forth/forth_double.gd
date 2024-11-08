class_name ForthDouble

extends ForthImplementationBase


func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				["2CONSTANT", two_constant],  # double
				["2VARIABLE", two_variable],  # double
				["D.", d_dot],  # double
				["D-", d_minus],  # double
				["D+", d_plus],  # double
				["D>S", d_to_s],  # double
				["D2*", d_two_star],  # double
				["D2/", d_two_slash],  # double
				["DABS", d_abs],  # double
				["DMAX", d_max],  # double
				["DMIN", d_min],  # double
				["DNEGATE", d_negate],  # double
				["M*/", m_star_slash],  # double
				["M+", m_plus],  # double
			]
		)
	)
	(
		forth
		. built_in_exec_functions
		. append_array(
			[
				two_constant_exec,
			]
		)
	)


func two_constant() -> void:
	# Create a dictionary entry for name, associated with constant double d.
	# ( d - )
	forth.create_dict_entry_name()
	# copy the execution token
	forth.ram.set_word(
		forth.dict_top, forth.address_from_built_in_function[two_constant_exec]
	)
	# store the constant
	forth.ram.set_dword(forth.dict_top + ForthRAM.CELL_SIZE, forth.pop_dword())
	forth.dict_top += ForthRAM.CELL_SIZE + ForthRAM.DCELL_SIZE


func two_constant_exec() -> void:
	# execution time functionality of _two_constant
	# return contents of double cell after execution token
	forth.push_dword(forth.ram.get_dword(forth.dict_ip + ForthRAM.CELL_SIZE))


func two_variable() -> void:
	# Create a ditionary entry for name associated with two cells of data
	# ( - )
	forth.core.create()
	# make room for one cell
	forth.dict_top += ForthRAM.DCELL_SIZE


func d_dot() -> void:
	forth.util.print_term(" " + str(forth.pop_dint()))


func d_minus() -> void:
	# Subtract d2 from d1, leaving the difference d3
	# ( d1 d2 - d3 )
	forth.ds_p += ForthRAM.DCELL_SIZE
	forth.ram.set_dint(
		forth.ds_p,
		(
			forth.ram.get_dint(forth.ds_p)
			- forth.ram.get_dint(forth.ds_p - ForthRAM.DCELL_SIZE)
		)
	)


func d_plus() -> void:
	# Add d1 to d2, leaving the sum d3
	# ( d1 d2 - d3 )
	forth.ds_p += ForthRAM.DCELL_SIZE
	forth.ram.set_dint(
		forth.ds_p,
		(
			forth.ram.get_dint(forth.ds_p)
			+ forth.ram.get_dint(forth.ds_p - ForthRAM.DCELL_SIZE)
		)
	)


func d_two_star() -> void:
	# Multiply d1 by 2, leaving the result d2
	# ( d1 - d2 )
	forth.ram.set_dint(forth.ds_p, forth.ram.get_dint(forth.ds_p) * 2)


func d_two_slash() -> void:
	# Divide d1 by 2, leaving the result d2
	# ( d1 - d2 )
	forth.ram.set_dint(forth.ds_p, forth.ram.get_dint(forth.ds_p) / 2)


func d_to_s() -> void:
	# Convert double to single, discarding MS cell.
	# ( d - n )
	# this assumes doubles are pushed in LS MS order
	forth.pop_int()


func d_abs() -> void:
	# Replace the top stack item with its absolute value
	# ( d - +d )
	forth.ram.set_dword(forth.ds_p, abs(forth.ram.get_dint(forth.ds_p)))


func d_max() -> void:
	# Return d3, the greater of d1 and d2
	# ( d1 d2 - d3 )
	forth.ds_p += ForthRAM.DCELL_SIZE
	if (
		forth.ram.get_dint(forth.ds_p)
		< forth.ram.get_dint(forth.ds_p - ForthRAM.DCELL_SIZE)
	):
		forth.ram.set_dint(
			forth.ds_p, forth.ram.get_dint(forth.ds_p - ForthRAM.DCELL_SIZE)
		)


func d_min() -> void:
	# Return d3, the lesser of d1 and d2
	# ( d1 d2 - d3 )
	forth.ds_p += ForthRAM.DCELL_SIZE
	if (
		forth.ram.get_dint(forth.ds_p)
		> forth.ram.get_dint(forth.ds_p - ForthRAM.DCELL_SIZE)
	):
		forth.ram.set_dint(
			forth.ds_p, forth.ram.get_dint(forth.ds_p - ForthRAM.DCELL_SIZE)
		)


func d_negate() -> void:
	# Change the sign of the top stack value
	# ( d - -d )
	forth.ram.set_dword(forth.ds_p, -forth.ram.get_dint(forth.ds_p))


func m_star_slash() -> void:
	# Multiply d1 by n1 producing a triple cell intermediate result t.
	# Divide t by n2, giving quotient d2.
	# Use this with n1 or n2 = 1 to accomplish double precision multiplication
	# or division.
	# ( d1 n1 +n2 - d2 )
	# Following is an *approximate* implementation, using the double float
	var q: float = (
		float(forth.ram.get_int(forth.ds_p + ForthRAM.CELL_SIZE))
		/ forth.ram.get_int(forth.ds_p)
	)
	forth.ds_p += ForthRAM.CELL_SIZE * 2
	forth.ram.set_dint(forth.ds_p, forth.ram.get_dint(forth.ds_p) * q)


func m_plus() -> void:
	# Add n to d1 leaving the sum d2
	# ( d1 n - d2 )
	forth.ds_p += ForthRAM.CELL_SIZE
	forth.ram.set_dint(
		forth.ds_p,
		(
			forth.ram.get_dint(forth.ds_p)
			+ forth.ram.get_int(forth.ds_p - ForthRAM.CELL_SIZE)
		)
	)
