using Godot;
using Godot.Collections;
// gdlint:ignore = max-public-methods
//# @WORDSET Core Extended

//#


//# Initialize (executed automatically by ForthCoreExt.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthCoreExt : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD .(
		//# Begin parsing a comment, terminated by ')'. Comment text
		//# will emit to the terminal when it is compiled.

	}//# @STACK ( - )
	public void DotLeftParenthesis()
	{
		Forth.Core.StartParenthesis();
		Forth.Type();


	//# @WORD \ IMMEDIATE
		//# Begin parsing a comment, terminated by end of line.

	}//# @STACK ( - )
	public void BackSlash()
	{
		Forth.Push(ForthTerminal.CR.ToAsciiBuffer()[0]);
		Parse();
		Forth.Core.TwoDrop();
	}


//# @WORDX \ #
	public void BackSlashExec()
	{
		BackSlash();
	}

	//# @WORD <>
	//# Return true if and only if n1 is not equal to n2.
	//# @STACK (	n1 n2 - flag )
	public void NotEqual()
	{
		var t = Forth.Pop();
		if(t != Forth.Pop())
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);
		}
	}

	//# @WORD 0<>
	//# Return true if and only if n is not equal to zero.
	//# @STACK ( n - flag )
	public void ZeroNotEqual()
	{
		if(Forth.Pop())
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);


	//# @WORD 0>
			//# Return true if and only if n is greater than zero.

		}
	}//# @STACK ( n - flag )
	public void ZeroGreaterThan()
	{
		if(Forth.Pop() > 0)
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);


	//# @WORD 2>R
			//# Pop the top two cells from the data stack and push them onto the
			//# return stack.

		}
	}//# @STACK (S: x1 x2 - )  (R: - x1 x2 )
	public void TwoToR()
	{
		Forth.RPushDint(Forth.PopDint());


	//# @WORD 2R>
		//# Pop the top two cells from the return stack and push them onto the
		//# data stack.

	}//# @STACK (S: - x1 x2 )  (R: x1 x2 - )
	public void TwoRFrom()
	{
		Forth.PushDint(Forth.RPopDint());


	//# @WORD 2R@
		//# Push a copy of the top two return stack cells onto the data stack.

	}//# @STACK (S: - x1 x2 ) (R: x1 x2 - x1 x2 )
	public void TwoRFetch()
	{
		var t = Forth.RPopDint();
		Forth.PushDint(t);
		Forth.RPushDint(t);


	//# @WORD AGAIN IMMEDIATE
		//# Unconditionally branch back to the point immediately following
		//# the nearest previous BEGIN.

	}//# @STACK ( dest - )
	public void Again()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTop, Forth.AddressFromBuiltInFunction[again_exec]);

		// The link back
		Forth.Ram.SetInt(Forth.DictTop + ForthRAM.CELL_SIZE, Forth.CfPopDest());
		Forth.DictTop += ForthRAM.DCELL_SIZE;


		// two cells up and done

	}//# @WORDX AGAIN
	public void AgainExec()
	{

		// Unconditionally branch
		Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CELL_SIZE);


	//# @WORD BUFFER:
		//# Create a dictionary entry for <name>, associated with n bytes of space.
		//# Usage: <n> BUFFER: <name>
		//# Executing <name> will return address of the starting byte on the stack.

	}//# @STACK ( "name" n - )
	public void BufferColon()
	{
		Forth.Core.Create();
		Forth.Core.Allot();


	//# @WORD C" IMMEDIATE
		//# Return the counted-string address of the string, terminated by ",
		//# which is in a temporary buffer. For compilation only

	}//# @STACK ( "string" - c-addr )
	public void CQuote()
	{
		Forth.Core.StartString();

		// compilation behavior
		if(Forth.State)
		{

			// copy the execution token


			Forth.Ram.SetInt(Forth.DictTop, Forth.AddressFromBuiltInFunction[c_quote_exec]);

			// store the value
			var l = Forth.Pop();
			// length of the string
			var src = Forth.Pop();
			// first byte address
			Forth.DictTop += ForthRAM.CELL_SIZE;
			Forth.Ram.SetByte(Forth.DictTop, l);
			// store the length
			// compile the string into the dictionary
			foreach(int i in l)
			{
				Forth.DictTop += 1;
				Forth.Ram.SetByte(Forth.DictTop, Forth.Ram.GetByte(src + i));
			}

		// this will align the dict top and save it
			Forth.Core.Align();
		}
	}


//# @WORDX C"
	public void CQuoteExec()
	{
		var l = Forth.Ram.GetByte(Forth.DictIp + ForthRAM.CELL_SIZE);
		Forth.Push(Forth.DictIp + ForthRAM.CELL_SIZE);
		// address of the string start
		// moves to string cell for l in 0..3, then one cell past for l in 4..7, etc.
		Forth.DictIp += ((l / ForthRAM.CELL_SIZE) + 1) * ForthRAM.CELL_SIZE;


	//# @WORD HEX
		//# Sets BASE to 16.

	}//# @STACK ( - )
	public void Hex()
	{
		Forth.Push(16);
		Forth.Core.Base();
		Forth.Core.Store();


	//# @WORD FALSE
		//# Return a false value: a single-cell with all bits clear.

	}//# @STACK ( - flag )
	public void FFalse()
	{
		Forth.Push(Forth.FALSE);


	//# @WORD MARKER
		//# Create a dictionary definition for <name>, to be used as a deletion
		//# boundary. When <name> is executed, remove the definition for <name>
		//# and all subsequent definitions. Usage: MARKER <name>

	}//# @STACK ( "name" - )
	public void Marker()
	{
		if(Forth.CreateDictEntryName())
		{

			// copy the execution token


			Forth.Ram.SetInt(Forth.DictTop, Forth.AddressFromBuiltInFunction[marker_exec]);

			// store the dict_p value in the next cell
			Forth.Ram.SetInt(Forth.DictTop + ForthRAM.CELL_SIZE, Forth.DictP);
			Forth.DictTop += ForthRAM.DCELL_SIZE;

			// preserve the state
			Forth.SaveDictTop();
		}
	}


//# @WORDX MARKER
	public void MarkerExec()
	{

		// execution time functionality of marker
		// set dict_p to the previous entry
		Forth.DictTop = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CELL_SIZE);
		Forth.DictP = Forth.Ram.GetInt(Forth.DictTop);
		Forth.SaveDictTop();
		Forth.SaveDictP();


	//# @WORD NIP
		//# Drop second stack item, leaving top unchanged.

	}//# @STACK ( x1 x2 - x2 )
	public void Nip()
	{
		Forth.Core.Swap();
		Forth.Core.Drop();


	//# @WORD PARSE
		//# Parse text to the first instance of char, returning the address
		//# and length of a temporary location containing the parsed text.
		//# Returns a counted string. Consumes the final delimiter.

	}//# @STACK ( char - c_addr n )
	public void Parse()
	{
		var count = 0;
		var ptr = Forth.WORD_START + 1;
		var delim = Forth.Pop();
		Forth.Core.Source();
		var source_size = Forth.Pop();
		var source_start = Forth.Pop();
		Forth.Core.ToIn();
		var ptraddr = Forth.Pop();
		Forth.Push(ptr);
		// parsed text begins here
		while(true)
		{


			var t = Forth.Ram.GetByte(source_start + Forth.Ram.GetInt(ptraddr));

			// increment the input pointer
			if(t != 0)
			{
				Forth.Ram.SetInt(ptraddr, Forth.Ram.GetInt(ptraddr) + 1);
			}

		// a null character also stops the parse
			if(t != 0 && t != delim)
			{
				Forth.Ram.SetByte(ptr, t);
				ptr += 1;
				count += 1;
			}
			else
			{
				break;
			}
		}
		Forth.Push(count);


	//# @WORD PARSE-NAME
		//# Skip leading delimiters and parse <name> delimited by a space. Return the
		//# address and length of the found name.

	}//# @STACK ( "name" - c-addr u )
	public void ParseName()
	{
		Forth.Push(ForthTerminal.BL.ToAsciiBuffer()[0]);
		Forth.Core.Word();
		Forth.Core.Count();


	//# @WORD PICK
		//# Place a copy of the nth stack entry on top of the stack.
		//# The zeroth item is the top of the stack, so 0 pick is dup.

	}//# @STACK ( +n - x )
	public void Pick()
	{
		var n = Forth.Pop();
		if(n >= Forth.DATA_STACK_SIZE - Forth.DsP)
		{
			Forth.Util.RprintTerm(" PICK outside data stack");
		}
		else
		{
			Forth.Push(Forth.DataStack[ - n - 1]);


	//# @WORD SOURCE-ID
			//# Return a value indicating current input source.
			//# Value is 0 for default user input, -1 for character string.

		}
	}//# @STACK ( - n )
	public void SourceId()
	{
		Forth.Push(Forth.SourceId);


	//# @WORD TO
		//# Store x in the data space associated with name (defined with VALUE).
		//# Usage: <x> TO <name>

	}//# @STACK ( "name" x - )
	public void To()
	{

		// get the name
		ParseName();
		var len = Forth.Pop();
		// length
		var caddr = Forth.Pop();
		// start
		var word = Forth.Util.StrFromAddrN(caddr, len);
		var token_addr_immediate = Forth.FindInDict(word);
		if(!token_addr_immediate[0])
		{
			Forth.Util.PrintUnknownWord(word);
		}
		else
		{

			// adjust to data field location


			Forth.Ram.SetInt(token_addr_immediate[0] + ForthRAM.CELL_SIZE, Forth.Pop());


	//# @WORD TRUE
			//# Return a true value, a single-cell value with all bits set.

		}
	}//# @STACK ( - flag )
	public void FTrue()
	{
		Forth.Push(Forth.TRUE);


	//# @WORD TUCK
		//# Place a copy of the top stack item below the second stack item.

	}//# @STACK ( x1 x2 - x2 x1 x2 )
	public void Tuck()
	{
		Forth.Core.Swap();
		Forth.Push(Forth.DataStack[Forth.DsP + 1]);


	//# @WORD U>
		//# Return true if and only if u1 is greater than u2.

	}//# @STACK ( u1 u2 - flag )
	public void ULessThan()
	{
		var u2 = Forth.Ram.Unsigned(Forth.Pop());
		if(Forth.Ram.Unsigned(Forth.Pop()) > u2)
		{
			Forth.Push(Forth.TRUE);
		}
		else
		{
			Forth.Push(Forth.FALSE);


	//# @WORD UNUSED
			//# Return u, the number of bytes remaining in the memory area
			//# where dictionary entries are constructed.

		}
	}//# @STACK ( - u )
	public void Unused()
	{
		Forth.Push(Forth.DICT_TOP - Forth.DictTop);


	//# @WORD VALUE
		//# Create a dictionary entry for name, associated with value x.
		//# Usage: <x> VALUE <name>

	}//# @STACK ( "name" x - )
	public void Value()
	{
		var init_val = Forth.Pop();
		if(Forth.CreateDictEntryName())
		{

			// copy the execution token


			Forth.Ram.SetInt(Forth.DictTop, Forth.AddressFromBuiltInFunction[value_exec]);

			// store the initial value
			Forth.Ram.SetInt(Forth.DictTop + ForthRAM.CELL_SIZE, init_val);
			Forth.DictTop += ForthRAM.DCELL_SIZE;

			// preserve the state
			Forth.SaveDictTop();
		}
	}


//# @WORDX VALUE
	public void ValueExec()
	{

		// execution time functionality of value
		// return contents of the cell after the execution token
		Forth.Push(Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CELL_SIZE));
	}


}
