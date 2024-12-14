using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class BlinkV : Forth.Words
    {
        public BlinkV(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "BLINKV";
            Description = "Send BLINK command to video terminal.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.BLINK);
        }
    }
}
