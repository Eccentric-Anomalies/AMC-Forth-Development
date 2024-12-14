using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class OneMinus : Forth.Words
    {
        public OneMinus(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "1-";
            Description = "Subtract one from n1, leaving n2.";
            StackEffect = "( n1 - n2 )";
        }

        public override void Call()
        {
            Forth.Push(1);
            Forth.CoreWords.Minus.Call();
        }
    }
}
