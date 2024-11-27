class_name ForthFileExt
## @WORDSET File Extended
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthFileExt.new())
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


## @WORD INCLUDE
## Parse the following word and use as file name with INCLUDED.
## @STACK ( i*x "filename" - j*x )
func include() -> void:
	forth.core_ext.parse_name()
	forth.file.included()
