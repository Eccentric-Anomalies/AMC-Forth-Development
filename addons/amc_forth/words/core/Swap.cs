using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Swap : Forth.Words
	{

		public Swap(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "SWAP";
			Description = "Exchange the top two items on the stack.";
			StackEffect = "( x1 x2 - x2 x1 )";
		}

		public override void Call()
		{
			var x1 = Forth.DataStack[Forth.DsP + 1];
			Forth.DataStack[Forth.DsP + 1] = Forth.DataStack[Forth.DsP];
			Forth.DataStack[Forth.DsP] = x1;
		}
	}
}