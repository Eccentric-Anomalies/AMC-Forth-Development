using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class LowV : Forth.Words
    {
        public LowV(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "LOWV";
            Description = "Send LOWINT (low intensity) command to video terminal.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.LOWINT);
        }
    }
}
