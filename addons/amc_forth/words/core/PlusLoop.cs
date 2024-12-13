using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class PlusLoop : Forth.Words
	{

		public PlusLoop(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "+LOOP";
			Description = 
				"Like LOOP but increment the index by the specified signed value n. After "+
				"incrementing, if the index crossed the boundary between the limit - 1 "+
				"and the limit, the loop is terminated.";
			StackEffect = "( dest orig n - )";
			Immediate = true;
		}

		public override void Call()
		{
			Forth.Ram.SetInt(Forth.DictTopP, XtX);
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
			Forth.SaveDictTop();	// preserve dictionary state
		}

        public override void CallExec()
        {
			// pull out the increment
			var n = Forth.Pop();
			Forth.CoreExtWords.TwoRFrom.Call();	// Move to loop params to the data stack.
			var i = Forth.Pop();
			// current index
			var limit = Forth.Pop();
			// limit value
			var above_before = i >= limit;
			var next_i = i + n;
			var above_after = next_i >= limit;
			if(above_before != above_after)
			{
				// loop is satisfied
				Forth.DictIp += ForthRAM.CellSize;
			}
			else
			{
				// loop must continue
				Forth.Push(limit);
				// original limit
				Forth.Push(next_i);
				// new index
				// Branch back. The DO or ?DO exec will push the values
				// back on the return stack
				Forth.DictIp = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
			}
        }
    }
}