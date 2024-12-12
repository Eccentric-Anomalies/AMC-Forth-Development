using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class False : Forth.Words
	{

		public False(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "FALSE";
			Description = "Return a false value: a single-cell with all bits clear.";
			StackEffect = "( - flag )";
		}

		public override void Call()
		{
			Forth.Push(AMCForth.False);
		}
	}
}