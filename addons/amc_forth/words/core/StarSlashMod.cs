using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class StarSlashMod : Forth.Words
	{

		public StarSlashMod(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "*/MOD";
			Description = 
				"Multiply n1 by n2 producing a double-cell result d. "+
				"Divide d by n3, giving the single-cell remainder n4 "+
				"and a single-cell quotient n5.";
			StackEffect = "( n1 n2 n3 - n4 n5 )";
		}

		public override void Call()
		{
			var n3 = Forth.Pop();
			var d = (double) Forth.Pop() * Forth.Pop();
			Forth.Push((int) (d % n3));
			Forth.Push((int) (d / n3));
		}
	}
}