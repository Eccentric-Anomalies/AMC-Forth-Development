using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class InvisibleV : Forth.Words
    {
        public InvisibleV(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "INVISIBLEV";
            Description = "Send INVISIBLE command to video terminal.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.INVISIBLE);
        }
    }
}
