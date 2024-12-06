using Godot;
using Godot.Collections;

//# @WORDSET Double Extended

//#


//# Initialize (executed automatically by ForthDoubleExt.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthDoubleExt : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	//# @WORD 2ROT
		//# Rotate the top three cell pairs on the stack.

	}//# @STACK ( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )
	public void TwoRot()
	{
		var t = Forth.GetDint(4);
		Forth.SetDint(4, Forth.GetDint(2));
		Forth.SetDint(2, Forth.GetDint(0));
		Forth.SetDint(0, t);
	}


}
