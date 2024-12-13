using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class TwoStore : Forth.Words
	{

		public TwoStore(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "2!";
			Description = 
				"Store the cell pair x1 x2 in the two cells beginning at a-addr, removing "+
				"three cells from the stack. The order of the two cells is the same as "+
				"on the stack, meaning the one in the top stack is in lower memory.";
			StackEffect = "( x1 x2 a-addr - )";
		}

		public override void Call()
		{
			var a = Forth.Pop();
			Forth.Ram.SetInt(a, Forth.Pop());
			Forth.Ram.SetInt(a + ForthRAM.CellSize, Forth.Pop());
		}
	}
}