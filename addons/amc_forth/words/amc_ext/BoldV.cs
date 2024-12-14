using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class BoldV : Forth.Words
    {
        public BoldV(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "BOLDV";
            Description = "Send BOLD command to video terminal.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.BOLD);
        }
    }
}
