using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class ReverseV : Forth.Words
    {
        public ReverseV(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "REVERSEV";
            Description = "Send REVERSE command to video terminal.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.REVERSE);
        }
    }
}
