using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Abs : Forth.Words
	{

		public Abs(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "ABS";
			Description = "Replace the top stack item with its absolute value.";
			StackEffect = "( n - +n )";
		}

		public override void Call()
		{
			Forth.DataStack[Forth.DsP] = System.Math.Abs(Forth.DataStack[Forth.DsP]);
		}
	}
}