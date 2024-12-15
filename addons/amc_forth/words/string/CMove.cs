using Godot;
using Godot.Collections;

namespace Forth.String
{
    [GlobalClass]
    public partial class CMove : Forth.Words
    {
        public CMove(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "CMOVE";
            Description =
                "Copy u characters from addr1 to addr2. The copy proceeds from LOWER to HIGHER addresses.";
            StackEffect = "( addr1 addr2 u - )";
        }

        public override void Call()
        {
            var u = Forth.Pop();
            var a2 = Forth.Pop();
            var a1 = Forth.Pop();
            var i = 0;

            // move in ascending order a1 -> a2, fast, then slow
            while (i < u)
            {
                if (u - i >= ForthRAM.DCellSize)
                {
                    Forth.Ram.SetDword(a2 + i, Forth.Ram.GetDword(a1 + i));
                    i += ForthRAM.DCellSize;
                }
                else
                {
                    Forth.Ram.SetByte(a2 + i, Forth.Ram.GetByte(a1 + i));
                    i += 1;
                }
            }
        }
    }
}
