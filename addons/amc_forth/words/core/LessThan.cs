using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class LessThan : Forth.Words
	{

		public LessThan(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "<";
			Description = "Return true if and only if n1 is less than n2.";
			StackEffect = "( n1 n2 - flag )";
		}

		public override void Call()
		{
			var t = Forth.Pop();
			if(t > Forth.Pop())
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