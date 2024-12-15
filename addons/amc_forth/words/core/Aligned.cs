using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Aligned : Forth.Words
    {
        public Aligned(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "ALIGNED";
            Description = "Return a-addr, the first aligned address greater than or equal to addr.";
            StackEffect = "( addr - a-addr )";
        }

        public override void Call()
        {
            var a = Forth.Pop();
            if (a % ForthRAM.CellSize != 0)
            {
                a = (a / ForthRAM.CellSize + 1) * ForthRAM.CellSize;
            }
            Forth.Push(a);
        }
    }
}
