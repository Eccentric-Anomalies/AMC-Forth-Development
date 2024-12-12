using Godot;

namespace Forth.Double
{
[GlobalClass]
	public partial class TwoVariable : Forth.Words
	{

		public TwoVariable(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "2VARIABLE";
			Description = 
				"Create a dictionary entry for name associated with two cells of data. "+
				"Executing <name> returns the address of the allocated cells.";
			StackEffect = "( 'name' - ), Execute: ( - addr )";
		}

		public override void Call()
		{
			Forth.CoreWords.Create.Call();
			Forth.DictTopP += ForthRAM.DCellSize;	// make room for one cell
			Forth.SaveDictTop();	// preserve dictionary state
		}
	}
}