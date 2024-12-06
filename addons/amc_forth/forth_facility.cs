using Godot;
using Godot.Collections;

//# @WORDSET Facility

//#


//# Initialize (executed automatically by ForthFacility.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthFacility : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD AT-XY
		//# Configure output device so next character display will appear
		//# at column u1, row u2 of the output area (origin in upper left).

	}//# @STACK ( u1 u2 - )
	public void AtXY()
	{
		var u2 = Forth.Pop();
		var u1 = Forth.Pop();
		Forth.Util.PrintTerm(ForthTerminal.ESC + "[%d;%dH" % new Array{u1, u2, });


	//# @WORD PAGE
		//# On a CRT, clear the screen and reset cursor position to the upper left
		//# corner.

	}//# @STACK ( - )
	public void Page()
	{
		Forth.Util.PrintTerm(ForthTerminal.CLRSCR);
		Forth.Push(1);
		Forth.Core.Dup();
		AtXY();
	}


}
