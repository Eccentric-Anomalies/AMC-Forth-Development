using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class RFrom : Forth.Words
	{

		public RFrom(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "R>";
			Description = "Remove the item on the top of the return stack and put it on the data stack.";
			StackEffect = "(S: - x ) (R: x - )";
		}

		public override void Call()
		{
			Forth.Push(Forth.RPop());
		}
	}
}