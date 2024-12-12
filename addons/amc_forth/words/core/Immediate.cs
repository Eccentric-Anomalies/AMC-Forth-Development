using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class Immediate : Forth.Words
	{

		public Immediate(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "IMMEDIATE";
			Description = "Make the most recent definition (top of the dictionary) an IMMEDIATE word.";
			StackEffect = "( - )";
		}

		public override void Call()
		{
			// Set the IMMEDIATE bit in the name length byte
			if(Forth.DictP != Forth.DictTopP)
			{
				// dictionary is not empty, get the length of the top entry name
				var length_byte_addr = Forth.DictP + ForthRAM.CellSize;
				// set the immediate bit in the length byte
				Forth.Ram.SetByte(length_byte_addr, Forth.Ram.GetByte(length_byte_addr) | AMCForth.ImmediateBitMask);
			}
		}
	}
}