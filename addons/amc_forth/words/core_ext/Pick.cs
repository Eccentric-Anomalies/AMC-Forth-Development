using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class Pick : Forth.Words
	{

		public Pick(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "PICK";
			Description = 
				"Place a copy of the nth stack entry on top of the stack. "+
				"The zeroth item is the top of the stack, so 0 pick is dup.";
			StackEffect = "( +n - x )";
		}

		public override void Call()
		{
			var n = Forth.Pop();
			if(n >= AMCForth.DataStackSize - Forth.DsP)
			{
				Forth.Util.RprintTerm(" PICK outside data stack");
			}
			else
			{
				Forth.Push(Forth.DataStack[ - n - 1]);
			}
		}
	}
}