using Godot;

namespace Forth.Double
{
    [GlobalClass]
    public partial class DDot : Forth.Words
    {
        public DDot(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "D.";
            Description = "Display the top cell pair on the stack as a signed double integer.";
            StackEffect = "( d - )";
        }

        public override void Call()
        {
            var fmt = Forth.Ram.GetInt(AMCForth.Base) == 10 ? "F0" : "X";
            var num = Forth.PopDint();
            Forth.Util.PrintTerm(" " + num.ToString(fmt));
        }
    }
}
