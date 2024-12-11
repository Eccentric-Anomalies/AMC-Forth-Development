using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class TwoStar : Forth.Words
	{

		public TwoStar(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "2*";
			Description = 
				"Return x2, result of shifting x1 one bit towards the MSB, "+
				"filling the LSB with zero.";
			StackEffect = "( x1 - x2 )";
		}

		public override void Call()
		{
			Forth.Push(Forth.Pop() << 1);
		}
	}
}