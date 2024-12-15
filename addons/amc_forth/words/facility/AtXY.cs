using Godot;

namespace Forth.Facility
{
    [GlobalClass]
    public partial class AtXY : Forth.Words
    {
        public AtXY(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "AT-XY";
            Description =
                "Configure output device so next character display will appear "
                + "at column u1, row u2 of the output area (origin in upper left).";
            StackEffect = "( u1 u2 - )";
        }

        public override void Call()
        {
            var u2 = Forth.Pop();
            var u1 = Forth.Pop();
            Forth.Util.PrintTerm(Terminal.ESC + System.String.Format("[{0};{1}H", u1, u2));
        }
    }
}
