using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class True : Forth.Words
    {
        public True(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "TRUE";
            Description = "Return a true value, a single-cell value with all bits set.";
            StackEffect = "( - flag )";
        }

        public override void Call()
        {
            Forth.Push(AMCForth.True);
        }
    }
}
