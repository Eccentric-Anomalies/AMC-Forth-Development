using Godot;
using Godot.Collections;

namespace Forth.String
{
	[GlobalClass]
	public partial class CMoveUp : Forth.Words
	{

		public CMoveUp(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "CMOVE>";
			Description = "Copy u characters from addr1 to addr2. The copy proceeds from HIGHER to LOWER addresses.";
			StackEffect = "( addr1 addr2 u - )";
		}

		public override void Call()
		{
			var u = Forth.Pop();
			var a2 = Forth.Pop();
			var a1 = Forth.Pop();
			var i = u;

			// move in descending order a1 -> a2, fast, then slow
			while(i > 0)
			{
				if(i >= ForthRAM.DCellSize)
				{
					i -= ForthRAM.DCellSize;
					Forth.Ram.SetDword(a2 + i, Forth.Ram.GetDword(a1 + i));
				}
				else
				{
					i -= 1;
					Forth.Ram.SetByte(a2 + i, Forth.Ram.GetByte(a1 + i));
				}
			}
		}
	}
}