using Godot;
using Godot.Collections;

//# @WORDSET File

//#


//# Initialize (executed automatically by ForthFile.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthFile : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD CLOSE-FILE
		//# Close the file identified by fileid. Return an I/O result code.
		//# Result code, ior, is zero for success.

	}//# @STACK ( fileid - ior )
	public void CloseFile()
	{
		Forth.FreeFileId(Forth.Pop());
		Forth.Push(0);


	//# @WORD INCLUDED
		//# Same as INCLUDE-FILE, except file is specified by its name, as a
		//# caddr and length u. The file is opened and its fileid is stored in
		//# SOURCE-ID.

	}//# @STACK ( i*x c-addr u - j*x )
	public void Included()
	{
		RO();
		//# read only
		OpenFile();
		var ior = Forth.Pop();
		var fileid = Forth.Pop();
		if(ior)
		{
			Forth.Util.RprintTerm(" File not found");
			return ;
		}
		Forth.Push(fileid);
		IncludeFile();


	//# @WORD INCLUDE_FILE
		//# Read and interpret the given file. Save the current input
		//# source specification, store the fileid in SOURCE-ID and
		//# make this file the input source. Read and interpret lines until EOF.

	}//# @STACK ( fileid - )
	public void IncludeFile()
	{
		var flag = Forth.True;
		var u2 = 0;
		var ior = 0;
		var fileid = Forth.Pop();

		// save the current source
		Forth.SourceIdStack.PushBack(Forth.SourceId);

		// new source id
		Forth.SourceId = fileid;

		// address of data buffer
		var buff_data = fileid + Forth.FileBuffDataOffset;
		var buff_size = Forth.FileBuffDataSize;
		while(!ior && flag == Forth.True)
		{

			// clear the buffer pointer
			Forth.Ram.SetInt(fileid + Forth.FileBuffPtrOffset, 0);
			Forth.Push(buff_data);
			Forth.Push(buff_size);
			Forth.Push(fileid);
			ReadLine();
			ior = Forth.Pop();
			flag = Forth.Pop();
			u2 = Forth.Pop();

			// process the line read, if any
			if(u2)
			{
				Forth.Push(buff_data);
				Forth.Push(u2);
				Forth.Core.Evaluate();
			}
		}

// restore the previous source
		Forth.SourceId = Forth.SourceIdStack.PopBack();

		// close the file
		Forth.Push(fileid);
		CloseFile();
		Forth.Pop();


		// remove the return code
		//# @WORD OPEN-FILE
		//# Open the file whose name is given by c-addr of length u, using file
		//# access method fam. On success, return ior of zero and a fileid, otherwise
		//# return non-zero ior and undefined fileid. Check user:// first, then res://.

	}//# @STACK (c-addr u fam - fileid ior )
	public void OpenFile()
	{
		var ior =  - 1;
		var fam = Forth.Pop();
		var u = Forth.Pop();
		var fname = Forth.Util.StrFromAddrN(Forth.Pop(), u);
		var file = FileAccess.Open("user://" + fname, fam);
		if(file == null)
		{
			file = FileAccess.Open("res://" + fname, fam);
		}
		var fileid = 0;
		if(file)
		{
			fileid = Forth.AssignFileId(file, fam);
			if(fileid)
			{
				ior = 0;
			}
			else
			{

				// failed to allocate a buffer
				Forth.Util.RprintTerm("File buffers exhausted");
			}
		}
		Forth.Push(fileid);
		Forth.Push(ior);


	//# @WORD R/O
		//# Return the read-only file access method.

	}//# @STACK ( - fam )
	public void RO()
	{
		Forth.Push(FileAccess.ModeFlags.Read);


	//# @WORD R/W
		//# Return the read-write file access method.

	}//# @STACK ( - fam )
	public void RW()
	{
		Forth.Push(FileAccess.ModeFlags.ReadWrite);


	//# @WORD READ-LINE
		//# Read and store one line of text from file and update FILE-POSITION. On
		//# success, ior is zero, flag is true and n2 is the number of chars read.
		//# On EOF, ior is zero, flag is false, and u2 is zero.

	}//# @STACK ( c-addr u1 fileid - u2 flag ior )
	public void ReadLine()
	{
		var file = Forth.GetFileFromId(Forth.Pop());
		var u1 = Forth.Pop();
		var c_addr = Forth.Pop();
		var u2 = 0;
		var flag = Forth.False;
		var ior = 0;
		var line = "";
		if(file && !file.EofReached())
		{

			// gdscript get_line does not include the end of line character
			line = file.GetLine();
			u2 = Mathf.Min(line.Length(), u1);
			flag = Forth.True;

			// copy incoming string to buffer
			Forth.Util.StringFromStr(c_addr, u1, line);

			// null terminate
			Forth.Ram.SetByte(c_addr + u2, 0);
		}
		Forth.Push(u2);
		Forth.Push(flag);
		Forth.Push(ior);


	//# @WORD W/O
		//# Return the write-only file access method.

	}//# @STACK ( - fam )
	public void WO()
	{
		Forth.Push(FileAccess.ModeFlags.Write);
	}


}
