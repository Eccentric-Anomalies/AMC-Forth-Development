using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Space : Forth.Words
    {
        public Space(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "SPACE";
            Description = "Display one space on the current output device.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.BL);
        }
    }
}
