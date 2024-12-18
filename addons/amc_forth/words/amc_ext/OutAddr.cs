using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class OutAddr : Words
    {
        public OutAddr(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "OUT-ADDR";
            Description = "Return memory addr from output port p.";
            StackEffect = "( p - addr )";
        }

        public override void Call()
        {
            Forth.Push(Forth.Pop() * ForthRAM.CellSize + AMCForth.IoOutStart);
        }
    }
}
