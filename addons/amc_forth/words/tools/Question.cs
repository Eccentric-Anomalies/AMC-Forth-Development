using Godot;
using Godot.Collections;

namespace Forth.Tools
{
    [GlobalClass]
    public partial class Question : Forth.Words
    {
        public Question(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "?";
            Description = "Fetch the cell contents of the given address and display.";
            StackEffect = "( a-addr - )";
        }

        public override void Call()
        {
            Forth.CoreWords.Fetch.Call();
            Forth.CoreWords.Dot.Call();
        }
    }
}
