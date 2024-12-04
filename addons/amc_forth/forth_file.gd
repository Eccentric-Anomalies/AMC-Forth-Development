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


## @WORD CLOSE-FILE
## Close the file identified by fileid. Return an I/O result code.
## Result code, ior, is zero for success.
## @STACK ( fileid - ior )
func close_file() -> void:
	forth.free_file_id(forth.pop())
	forth.push(0)


## @WORD INCLUDED
## Same as INCLUDE-FILE, except file is specified by its name, as a
## caddr and length u. The file is opened and its fileid is stored in
## SOURCE-ID.
## @STACK ( i*x c-addr u - j*x )
func included() -> void:
	r_o()  ## read only
	open_file()
	var ior: int = forth.pop()
	var fileid: int = forth.pop()
	if ior:
		forth.util.rprint_term(" File not found")
		return
	forth.push(fileid)
	include_file()


## @WORD INCLUDE_FILE
## Read and interpret the given file. Save the current input
## source specification, store the fileid in SOURCE-ID and
## make this file the input source. Read and interpret lines until EOF.
## @STACK ( fileid - )
func include_file() -> void:
	var flag: int = forth.TRUE
	var u2: int = 0
	var ior: int = 0
	var fileid: int = forth.pop()
	# save the current source
	forth.source_id_stack.push_back(forth.source_id)
	# new source id
	forth.source_id = fileid
	# address of data buffer
	var buff_data: int = fileid + forth.FILE_BUFF_DATA_OFFSET
	var buff_size: int = forth.FILE_BUFF_DATA_SIZE
	while not ior and flag == forth.TRUE:
		# clear the buffer pointer
		forth.ram.set_int(fileid + forth.FILE_BUFF_PTR_OFFSET, 0)
		forth.push(buff_data)
		forth.push(buff_size)
		forth.push(fileid)
		read_line()
		ior = forth.pop()
		flag = forth.pop()
		u2 = forth.pop()
		# process the line read, if any
		if u2:
			forth.push(buff_data)
			forth.push(u2)
			forth.core.evaluate()
	# restore the previous source
	forth.source_id = forth.source_id_stack.pop_back()
	# close the file
	forth.push(fileid)
	close_file()
	forth.pop()  # remove the return code


## @WORD OPEN-FILE
## Open the file whose name is given by c-addr of length u, using file
## access method fam. On success, return ior of zero and a fileid, otherwise
## return non-zero ior and undefined fileid. Check user:// first, then res://.
## @STACK (c-addr u fam - fileid ior )
func open_file() -> void:
	var ior: int = -1
	var fam: int = forth.pop()
	var u: int = forth.pop()
	var fname: String = forth.util.str_from_addr_n(forth.pop(), u)
	var file: FileAccess = FileAccess.open("user://" + fname, fam)
	if file == null:
		file = FileAccess.open("res://" + fname, fam)
	var fileid: int = 0
	if file:
		fileid = forth.assign_file_id(file, fam)
		if fileid:
			ior = 0
		else:
			# failed to allocate a buffer
			forth.util.rprint_term("File buffers exhausted")
	forth.push(fileid)
	forth.push(ior)


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


## @WORD READ-LINE
## Read and store one line of text from file and update FILE-POSITION. On
## success, ior is zero, flag is true and n2 is the number of chars read.
## On EOF, ior is zero, flag is false, and u2 is zero.
## @STACK ( c-addr u1 fileid - u2 flag ior )
func read_line() -> void:
	var file: FileAccess = forth.get_file_from_id(forth.pop())
	var u1: int = forth.pop()
	var c_addr: int = forth.pop()
	var u2: int = 0
	var flag: int = forth.FALSE
	var ior: int = 0
	var line: String = ""
	if file and not file.eof_reached():
		# gdscript get_line does not include the end of line character
		line = file.get_line()
		u2 = min(line.length(), u1)
		flag = forth.TRUE
		# copy incoming string to buffer
		forth.util.string_from_str(c_addr, u1, line)
		# null terminate
		forth.ram.set_byte(c_addr + u2, 0)
	forth.push(u2)
	forth.push(flag)
	forth.push(ior)


## @WORD W/O
## Return the write-only file access method.
## @STACK ( - fam )
func w_o() -> void:
	forth.push(FileAccess.WRITE)
