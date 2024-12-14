using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class TwoDrop : Forth.Words
    {
        public TwoDrop(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "2DROP";
            Description = "Remove the top pair of cells from the stack.";
            StackEffect = "( x1 x2 - )";
        }

        public override void Call()
        {
            Forth.Pop();
            Forth.Pop();
        }
    }
}
