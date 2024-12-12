using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class ZeroNotEqual : Forth.Words
	{

		public ZeroNotEqual(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "0<>";
			Description = "Return true if and only if n is not equal to zero.";
			StackEffect = "( n - flag )";
		}

		public override void Call()
		{
			if(Forth.Pop() != 0)
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