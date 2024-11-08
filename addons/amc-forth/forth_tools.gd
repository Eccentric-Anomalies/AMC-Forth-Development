class_name ForthTools

extends ForthImplementationBase


func _init(_forth: AMCForth) -> void:
	super(_forth)
	(
		forth
		. built_in_names
		. append_array(
			[
				["?", question],  # tools
			]
		)
	)



func question() -> void:
	# Fetch the contents of the given address and display
	# ( a-addr - )
	forth.core.fetch()
	forth.core.dot()

