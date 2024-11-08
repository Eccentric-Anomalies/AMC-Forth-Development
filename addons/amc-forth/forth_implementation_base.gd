class_name ForthImplementationBase

extends RefCounted

var forth: AMCForth

# Create with a reference to AMCForth
func _init(_forth: AMCForth):
	forth = _forth
