using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Then : Forth.Words
	{

		public Then(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "THEN";
			Description = "Place a reference to the this address at the address on the cf stack.";
			StackEffect = "( orig - )";
			Immediate = true;
		}

		public override void Call()
		{
			// Note: this only places the forward reference to the position
			// just before this (the caller will step to the next location).
			// No compiled function is needed.
			Forth.Ram.SetInt(Forth.CfPopOrig(), Forth.DictTopP - ForthRAM.CellSize);
		}
	}
}