using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class ZeroGreaterThan : Forth.Words
	{

		public ZeroGreaterThan(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "0>";
			Description = "Return true if and only if n is greater than zero.";
			StackEffect = "( n - flag )";
		}

		public override void Call()
		{
			if(Forth.Pop() > 0)
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