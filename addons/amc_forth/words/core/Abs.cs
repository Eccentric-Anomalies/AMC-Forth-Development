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
			// Absolute value of MAX-INT+1 is a noop
			if (Forth.DataStack[Forth.DsP] != int.MinValue)
			{
				Forth.DataStack[Forth.DsP] = System.Math.Abs(Forth.DataStack[Forth.DsP]);
			}
		}
	}
}