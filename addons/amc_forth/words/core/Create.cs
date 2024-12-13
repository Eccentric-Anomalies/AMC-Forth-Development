using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Create : Forth.Words
	{

		public Create(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "CREATE";
			Description = 
				"Construct a dictionary entry for the next token <name> in the input stream. "+
				"Execution of <name> will return the address of its data space.";
			StackEffect = "( 'name' - ), Execute: ( - addr )";
		}

		public override void Call()
		{
			if(Forth.CreateDictEntryName() != 0)
			{
				Forth.Ram.SetInt(Forth.DictTopP, XtX);
				Forth.DictTopP += ForthRAM.CellSize;
				Forth.SaveDictTop();	// preserve dictionary state
			}
		}

        public override void CallExec()
        {
			// return address of cell after execution token
			Forth.Push(Forth.DictIp + ForthRAM.CellSize);
			Forth.DictIp += ForthRAM.CellSize;
        }
    }
}