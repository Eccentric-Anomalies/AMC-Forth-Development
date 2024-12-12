using Godot;

namespace Forth.Double
{
[GlobalClass]
	public partial class DToS : Forth.Words
	{

		public DToS(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "D>S";
			Description = "Convert double to single, discarding MS cell.";
			StackEffect = "( d - n )";
		}

		public override void Call()
		{
			// this assumes doubles are pushed in LS MS order
			Forth.Pop();
		}
	}
}