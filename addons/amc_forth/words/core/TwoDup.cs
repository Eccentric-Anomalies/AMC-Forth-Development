using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class TwoDup : Forth.Words
    {
        public TwoDup(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "2DUP";
            Description = "Duplicate the top cell pair.";
            StackEffect = "(x1 x2 - x1 x2 x1 x2 )";
        }

        public override void Call()
        {
            var x2 = Forth.DataStack[Forth.DsP];
            var x1 = Forth.DataStack[Forth.DsP + 1];
            Forth.Push(x1);
            Forth.Push(x2);
        }
    }
}
