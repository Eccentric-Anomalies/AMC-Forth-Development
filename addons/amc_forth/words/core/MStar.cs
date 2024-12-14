using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class MStar : Forth.Words
    {
        public MStar(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "M*";
            Description = "Multiply n1 by n2, leaving the double result d.";
            StackEffect = "( n1 n2 - d )";
        }

        public override void Call()
        {
            Forth.PushDint((long)Forth.Pop() * Forth.Pop());
        }
    }
}
