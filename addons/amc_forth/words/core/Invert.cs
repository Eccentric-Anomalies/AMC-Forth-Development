using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Invert : Forth.Words
    {
        public Invert(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "INVERT";
            Description = "Invert all bits of x1, giving its logical inverse, x2.";
            StackEffect = "( x1 - x2 )";
        }

        public override void Call()
        {
            Forth.DataStack[Forth.DsP] = ~Forth.DataStack[Forth.DsP];
        }
    }
}
