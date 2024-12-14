using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Negate : Forth.Words
    {
        public Negate(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "NEGATE";
            Description = "Change the sign of the top stack value.";
            StackEffect = "( n - -n )";
        }

        public override void Call()
        {
            Forth.DataStack[Forth.DsP] = -Forth.DataStack[Forth.DsP];
        }
    }
}
