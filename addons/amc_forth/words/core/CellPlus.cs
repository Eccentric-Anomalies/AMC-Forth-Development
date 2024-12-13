using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class CellPlus : Forth.Words
	{

		public CellPlus(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "CELL+";
			Description = "Add the size in bytes of a cell to a_addr1, returning a_addr2.";
			StackEffect = "( a-addr1 - a-addr2 )";
		}

		public override void Call()
		{
			Forth.Push(ForthRAM.CellSize);
			Forth.CoreWords.Plus.Call();
		}
	}
}