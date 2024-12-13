using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class ToR : Forth.Words
	{

		public ToR(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = ">R";
			Description = "Remove the item on top of the data stack and put it on the return stack.";
			StackEffect = "(S: x - ) (R: - x )";
		}

		public override void Call()
		{
			Forth.RPush(Forth.Pop());
		}
	}
}