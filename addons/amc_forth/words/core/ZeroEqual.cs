using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class ZeroEqual : Forth.Words
	{

		public ZeroEqual(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "0=";
			Description = "Return true if and only if n is equal to zero.";
			StackEffect = "( n - flag )";
		}

		public override void Call()
		{
			if (Forth.Pop() != 0)
			{
				Forth.Push(AMCForth.False);
			}
			else
			{
				Forth.Push(AMCForth.True);
			}
		}
	}
}