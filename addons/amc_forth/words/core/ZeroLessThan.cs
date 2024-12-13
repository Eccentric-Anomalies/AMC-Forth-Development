using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class ZeroLessThan : Forth.Words
	{

		public ZeroLessThan(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "0<";
			Description = "Return true if and only if n is less than zero.";
			StackEffect = "( n - flag )";
		}

		public override void Call()
		{
			if(Forth.Pop() < 0)
			{
				Forth.Push(AMCForth.True);
			}
			else
			{
				Forth.Push(AMCForth.False);
			}
		}
	}
}