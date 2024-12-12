using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Leave : Forth.Words
	{

		public Leave(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "LEAVE";
			Description = 
				"Discard loop parameters and continue execution immediately following "+
				"the next LOOP or LOOP+ containing this LEAVE.";
			StackEffect = "( - )";
			Immediate = true;
		}

		public override void Call()
		{
			Forth.Ram.SetInt(Forth.DictTopP, XtX);	// copy the execution token
			// leave a special LEAVE link address on the leave control stack
			Forth.LcfPush(Forth.DictTopP + ForthRAM.CellSize);
			// move up to finish
			Forth.DictTopP += ForthRAM.DCellSize;	// two cells up
			// preserve dictionary state
			Forth.SaveDictTop();
		}

        public override void CallExec()
        {
			// Discard loop parameters
			Forth.RPop();
			Forth.RPop();
			// Skip ahead to the LOOP address in the next cell
			Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
        }
    }
}