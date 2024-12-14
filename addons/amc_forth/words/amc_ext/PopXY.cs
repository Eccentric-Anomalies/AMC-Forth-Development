using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class PopXY : Forth.Words
    {
        public PopXY(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "POP-XY";
            Description =
                "Configure output device so next character display will appear "
                + "at the column and row that were last saved with PUSH-XY.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.Util.PrintTerm(Terminal.ESC + "8");
        }
    }
}
