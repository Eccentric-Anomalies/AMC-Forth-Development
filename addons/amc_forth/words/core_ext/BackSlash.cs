using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class BackSlash : Forth.Words
    {
        public BackSlash(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "\\";
            Description = "Begin parsing a comment, terminated by end of line.";
            StackEffect = "( - )";
            Immediate = true;
        }

        public override void Call()
        {
            Forth.Push(Terminal.CR.ToAsciiBuffer()[0]);
            Forth.CoreExtWords.Parse.Call();
            Forth.CoreWords.TwoDrop.Call();
        }
    }
}
