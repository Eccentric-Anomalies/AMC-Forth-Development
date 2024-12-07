using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Aligned : Forth.WordBase
	{

		public Aligned(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "ALIGNED";
			Description = "Return a-addr, the first aligned address greater than or equal to addr.";
			StackEffect = "( addr - a-addr )";

		}

		public override void Execute()
		{
			var a = Forth.Pop();
			if(a % ForthRAM.CELL_SIZE != 0)
			{
				a = (a / ForthRAM.CELL_SIZE + 1) * ForthRAM.CELL_SIZE;
			}
			Forth.Push(a);
		}
	}
}