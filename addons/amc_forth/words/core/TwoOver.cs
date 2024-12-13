using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class TwoOver : Forth.Words
	{

		public TwoOver(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "2OVER";
			Description = "Copy a cell pair x1 x2 to the top of the stack.";
			StackEffect = "( x1 x2 x3 x4 - x1 x2 x3 x4 x1 x2 )";
		}

		public override void Call()
		{
			var x2 = Forth.DataStack[Forth.DsP + 2];
			var x1 = Forth.DataStack[Forth.DsP + 3];
			Forth.Push(x1);
			Forth.Push(x2);
		}
	}
}