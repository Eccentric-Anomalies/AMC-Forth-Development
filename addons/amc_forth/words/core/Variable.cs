using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Variable : Forth.Words
	{

		public Variable(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "VARIABLE";
			Description = 
				"Create a dictionary entry for name associated with one cell of data. "+
				"Executing <name> returns the address of the allocated cell.";
			StackEffect = "Compile: ( 'name' - ), Execute: ( - addr )";
		}

		public override void Call()
		{
			Forth.CoreWords.Create.Call();
			// make room for one cell
			Forth.DictTopP += ForthRAM.CellSize;
			// preserve dictionary state
			Forth.SaveDictTop();
		}
	}
}