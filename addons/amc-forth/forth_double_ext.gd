class_name ForthDoubleExt

extends ForthImplementationBase


func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				["2ROT", two_rot],  # double ext
			]
		)
	)


func two_rot() -> void:
	# rotate the top three cell pairs on the stack
	# ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
	var t: int = forth.ram.get_dword(forth.ds_p + 2 * ForthRAM.DCELL_SIZE)
	forth.ram.set_dword(
		forth.ds_p + 2 * ForthRAM.DCELL_SIZE,
		forth.ram.get_dword(forth.ds_p + ForthRAM.DCELL_SIZE)
	)
	forth.ram.set_dword(
		forth.ds_p + ForthRAM.DCELL_SIZE, forth.ram.get_dword(forth.ds_p)
	)
	forth.ram.set_dword(forth.ds_p, t)
