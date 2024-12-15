using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class TwoSwap : Forth.Words
    {
        public TwoSwap(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "2SWAP";
            Description = "Exchange the top two cell pairs.";
            StackEffect = "( x1 x2 x3 x4 - x3 x4 x1 x2 )";
        }

        public override void Call()
        {
            var x2 = Forth.DataStack[Forth.DsP + 2];
            var x1 = Forth.DataStack[Forth.DsP + 3];
            Forth.DataStack[Forth.DsP + 3] = Forth.DataStack[Forth.DsP + 1];
            Forth.DataStack[Forth.DsP + 2] = Forth.DataStack[Forth.DsP];
            Forth.DataStack[Forth.DsP + 1] = x1;
            Forth.DataStack[Forth.DsP] = x2;
        }
    }
}
