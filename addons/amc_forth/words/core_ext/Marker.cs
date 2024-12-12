using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class Marker : Forth.Words
	{

		public Marker(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "MARKER";
			Description = 
				"Create a dictionary definition for <name>, to be used as a deletion "+
				"boundary. When <name> is executed, remove the definition for <name> "+
				"and all subsequent definitions. Usage: MARKER <name>";
			StackEffect = "( 'name' - )";
		}

		public override void Call()
		{
			if(Forth.CreateDictEntryName() != 0)
			{
				// copy the execution token
				Forth.Ram.SetInt(Forth.DictTopP, XtX);
				// store the dict_p value in the next cell
				Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, Forth.DictP);
				Forth.DictTopP += ForthRAM.DCellSize;
				Forth.SaveDictTop();	// preserve the state
			}
		}

        public override void CallExec()
        {
			// execution time functionality of marker
			// set dict_p to the previous entry
			Forth.DictTopP = Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize);
			Forth.DictP = Forth.Ram.GetInt(Forth.DictTopP);
			Forth.SaveDictTop();
			Forth.SaveDictP();
        }
    }
}