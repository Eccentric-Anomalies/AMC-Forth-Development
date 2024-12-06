using Godot;
using Godot.Collections;

//# @WORDSET Tools Extended

//#


//# Initialize (executed automatically by ForthToolsExt.new())
//#
//# (1) All functions with "## @WORD <word>" comment will become
//# the default implementation for the built-in word.
//# (2) All functions with "## @WORDX <word>" comment will become
//# the *compiled* implementation for the built-in word.
//# (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
//# (4) UP TO four comments beginning with "##" before function
//# (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthToolsExt : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		base.Initialize(_forth);


	//# @WORD AHEAD IMMEDIATE
		//# Place forward reference origin on the control flow stack.

	}//# @STACK ( - orig )
	public void Ahead()
	{

		// copy the execution token


		Forth.Ram.SetInt(Forth.DictTop, Forth.AddressFromBuiltInFunction["AheadExec"]);

		// leave link address on the control stack
		Forth.CfPushOrig(Forth.DictTop + ForthRAM.CELL_SIZE);

		// move up to finish
		Forth.DictTop += ForthRAM.DCELL_SIZE;
		// two cells up
		// preserve dictionary state
		Forth.SaveDictTop();
	}


//# @WORDX AHEAD
	public void AheadExec()
	{

		// Branch to ELSE if top of stack not TRUE.
		// ( x - )
		// Skip ahead to the address in the next cell
		Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CELL_SIZE);


	//# WORD@ CS-PICK IMMEDIATE
		//# Place copy of the uth CS entry on top of the CS stack.

	}//# @STACK ( i*x u - i*x x_u )
	public void CsPick()
	{
		Forth.CfStackPick(Forth.Pop());


	//# WORD@ CS-ROLL IMMEDIATE
		//# Move the uth CS entry on top of the CS stack.

	}//# @STACK ( i*x u - i*x x_u )
	public void CsRoll()
	{
		Forth.CfStackRoll(Forth.Pop());
	}


}
