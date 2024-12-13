using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class StarSlash : Forth.Words
	{

		public StarSlash(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "*/";
			Description = 
				"Multiply n1 by n2 producing a double-cell result d. "+
				"Divide d by n3, giving the single-cell quotient n4.";
			StackEffect = "( n1 n2 n3 - n4 )";
		}

		public override void Call()
		{
			var n3 = Forth.Pop();
			Forth.Push((int)((double)Forth.Pop() * Forth.Pop() / n3));
		}
	}
}