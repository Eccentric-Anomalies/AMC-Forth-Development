using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Chars : Forth.Words
    {
        public Chars(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "CHARS";
            Description = "Return n2, the size in bytes of n1 characters. May be a no-op.";
            StackEffect = "( n1 - n2 )";
        }

        public override void Call()
        {
            // nothing to do. characters are 1 byte.
        }
    }
}
