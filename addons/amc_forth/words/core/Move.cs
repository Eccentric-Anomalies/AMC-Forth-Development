using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Move : Forth.Words
	{

		public Move(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "MOVE";
			Description = 
				"Copy u byes from a source starting at addr1, to the destination" +
				" starting at addr2. This works even if the ranges overlap.";
			StackEffect = "( addr1 addr2 u - )";
		}

		public override void Call()
		{
			var a1 = Forth.DataStack[Forth.DsP + 2];
			var a2 = Forth.DataStack[Forth.DsP + 1];
			var u = Forth.DataStack[Forth.DsP];
			if(a1 == a2 || u == 0)
			{

				// string doesn't need to move. Clean the stack and return.
				Forth.CoreWords.Drop.Call();
				Forth.CoreWords.Drop.Call();
				Forth.CoreWords.Drop.Call();
				return ;
			}
			if(a1 > a2)
			{

				// potentially overlapping, source above dest
				Forth.StringWords.CMove.Call();
			}
			else
			{

				// potentially overlapping, source below dest
				Forth.StringWords.CMoveUp.Call();
			}
		}
	}
}