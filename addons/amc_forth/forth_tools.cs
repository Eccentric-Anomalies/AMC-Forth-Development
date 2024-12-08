using Godot;
using Godot.Collections;

//# @WORDSET Tools

//#


//# Initialize (executed automatically by ForthTools.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthTools : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD ?
		//# Fetch the cell contents of the given address and display.

	}//# @STACK ( a-addr - )
	public void Question()
	{
		Forth.Core.Fetch();
		Forth.Core.Dot();


	//# @WORD .S
		//# Display the contents of the data stack using the current base.

	}//# @STACK ( - )
	public void DotS()
	{
		var pointer = Forth.DataStackTop;
		var fmt = ( Forth.Ram.GetInt(Forth.Base) == 10 ? "%d" : "%x" );
		Forth.Util.RprintTerm("");
		while(pointer >= Forth.DsP)
		{
			Forth.Util.PrintTerm(" " + fmt % Forth.DataStack[pointer]);
			pointer -= 1;
		}
		Forth.Util.PrintTerm(" <-Top");


	//# @WORD WORDS
		//# List all the definition names in the word list of the search order.
		//# Returns dictionary names first, including duplicates, then built-in names.

	}//# @STACK ( - )
	public void Words()
	{
		var word_len;
		var col = "WORDS".Length() + 1;
		Forth.Util.PrintTerm(" ");
		if(Forth.DictP != Forth.DictTopP)
		{

			// dictionary is not empty
			var p = Forth.DictP;
			while(p !=  - 1)
			{
				Forth.Push(p + ForthRAM.CellSize);
				Forth.Core.Count();
				// search word in addr, n format
				Forth.Core.Dup();
				// retrieve the size
				word_len = Forth.Pop();
				if(col + word_len + 1 >= ForthTerminal.COLUMNS - 2)
				{
					Forth.Util.PrintTerm(ForthTerminal.CRLF);
					col = 0;
				}
				col += word_len + 1;

				// emit the dictionary entry name
				Forth.Core.Type();
				Forth.Util.PrintTerm(" ");

				// drill down to the next entry
				p = Forth.Ram.GetInt(p);
			}
		}

// now go through the built-in names
		foreach(Variant entry in Forth.BuiltInNames)
		{
			word_len = entry[0].Length();
			if(col + word_len + 1 >= ForthTerminal.COLUMNS - 2)
			{
				Forth.Util.PrintTerm(ForthTerminal.CRLF);
				col = 0;
			}
			col += word_len + 1;
			Forth.Util.PrintTerm(entry[0] + " ");
		}
	}


}
