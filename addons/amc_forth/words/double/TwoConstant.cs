using Godot;

namespace Forth.Double
{
[GlobalClass]
	public partial class TwoConstant : Forth.Words
	{

		public TwoConstant(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "2CONSTANT";
			Description = "Create a dictionary entry for name, associated with constant double d.";
			StackEffect = "( 'name' d - ), Execute: ( - d )";
		}

		public override void Call()
		{
			var init_val = Forth.PopDword();
			if(Forth.CreateDictEntryName() != 0)
			{
				Forth.Ram.SetInt(Forth.DictTopP, XtX);	// copy the execution token
				// store the constant
				Forth.Ram.SetDword(Forth.DictTopP + ForthRAM.CellSize, init_val);
				Forth.DictTopP += ForthRAM.CellSize + ForthRAM.DCellSize;

				// preserve dictionary state
				Forth.SaveDictTop();
			}
		}

        public override void CallExec()
        {
			// return contents of double cell after execution token
			Forth.PushDword(Forth.Ram.GetDword(Forth.DictIp + ForthRAM.CellSize));
        }
    }
}