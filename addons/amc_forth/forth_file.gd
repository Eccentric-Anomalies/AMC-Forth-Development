class_name ForthFile
## @WORDSET File
##

extends ForthImplementationBase


## Initialize (executed automatically by ForthFile.new())
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


## @WORD INCLUDED
## Same as INCLUDE-FILE, except file is specified by its name, as a
## caddr and length u. The file is opened and its fileid is stored in
## SOURCE-ID.
## @STACK ( i*x c-addr u - j*x )
func included() -> void:
	forth.source_id = 99  # FIXME


## @WORD R/O
## Return the read-only file access method.
## @STACK ( - fam )
func r_o() -> void:
	forth.push(FileAccess.READ)


## @WORD R/W
## Return the read-write file access method.
## @STACK ( - fam )
func r_w() -> void:
	forth.push(FileAccess.READ_WRITE)


## @WORD W/O
## Return the write-only file access method.
## @STACK ( - fam )
func w_o() -> void:
	forth.push(FileAccess.WRITE)
