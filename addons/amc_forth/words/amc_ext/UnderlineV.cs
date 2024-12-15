using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class UnderlineV : Forth.Words
    {
        public UnderlineV(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "UNDERLINEV";
            Description = "Send UNDERLINE command to video terminal.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.UNDERLINE);
        }
    }
}
