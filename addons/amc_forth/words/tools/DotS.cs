using Godot;
using Godot.Collections;

namespace Forth.Tools
{
    [GlobalClass]
    public partial class DotS : Forth.Words
    {
        public DotS(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = ".S";
            Description = "Display the contents of the data stack using the current base.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            var pointer = AMCForth.DataStackTop;
            var fmt = Forth.Ram.GetInt(AMCForth.Base) == 10 ? "F0" : "X";
            Forth.Util.RprintTerm("");
            while (pointer >= Forth.DsP)
            {
                Forth.Util.PrintTerm(" " + Forth.DataStack[pointer].ToString(fmt));
                pointer -= 1;
            }
            Forth.Util.PrintTerm(" <-Top");
        }
    }
}
