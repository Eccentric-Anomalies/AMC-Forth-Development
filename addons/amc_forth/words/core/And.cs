using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class And : Forth.Words
	{

		public And(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "AND";
			Description = "Return x3, the bit-wise logical AND of x1 and x2.";
			StackEffect = "( x1 x2 - x3)";
		}

		public override void Call()
		{
			Forth.Push(Forth.Pop() & Forth.Pop());
		}
	}
}