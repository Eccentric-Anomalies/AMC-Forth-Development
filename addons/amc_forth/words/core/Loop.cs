using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Loop : Forth.Words
	{

		public Loop(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "LOOP";
			Description = 
				"Increment the index value by one and compare to the limit value. "+
				"If they are equal, continue with the next instruction, otherwise "+
				"return to the address of the preceding DO.";
			StackEffect = "( dest orig - )";
			Immediate = true;
		}

		public override void Call()
		{
			Forth.Ram.SetInt(Forth.DictTopP, XtX);	// copy the execution token
			// Check for any orig links
			while(!Forth.LcfIsEmpty())
			{
				// destination is on top of the back link
				Forth.Ram.SetInt(Forth.LcfPop(), Forth.DictTopP + ForthRAM.CellSize);
			}
			// The link back
			Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, Forth.CfPopDest());
			Forth.DictTopP += ForthRAM.DCellSize;
			// two cells up and done
			// preserve dictionary state
			Forth.SaveDictTop();
		}

        public override void CallExec()
        {
			Forth.CoreExtWords.TwoRFrom.Call();	// Move to data stack.
			Forth.CoreWords.OnePlus.Call();	// Increment the count
			Forth.CoreWords.TwoDup.Call();	// Duplicate them
			Forth.CoreWords.Equal.Call();	// Check for equal
			if(Forth.Pop() == 0)
			{
				// not matched, branch back. The DO exec will push the values
				// back on the return stack.
				Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
			}
			else
			{
				Forth.CoreWords.TwoDrop.Call();	// spare pair of loop parameters is not needed.
				Forth.DictIp += ForthRAM.CellSize;	// step ahead over the branch
			}
        }
    }
}