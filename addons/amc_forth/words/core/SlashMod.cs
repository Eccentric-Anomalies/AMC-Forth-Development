using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class SlashMod : Forth.Words
	{

		public SlashMod(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "/MOD";
			Description = "Divide n1 by n2, leaving the remainder n3 and quotient n4.";
			StackEffect = "( n1 n2 - n3 n4 )";
		}

		public override void Call()
		{
			var div = Forth.Pop();
			var d = Forth.Pop();
			Forth.Push(d % div);
			Forth.Push(d / div);
		}
	}
}