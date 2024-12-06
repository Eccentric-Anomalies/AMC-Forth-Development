using Godot;
using Godot.Collections;

//# @WORDSET File Extended

//#


//# Initialize (executed automatically by ForthFileExt.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthFileExt : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD INCLUDE
		//# Parse the following word and use as file name with INCLUDED.

	}//# @STACK ( i*x "filename" - j*x )
	public void Include()
	{
		Forth.CoreExt.ParseName();
		Forth.File.Included();
	}


}
