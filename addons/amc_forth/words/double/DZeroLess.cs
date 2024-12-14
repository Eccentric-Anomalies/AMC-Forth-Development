using Godot;

namespace Forth.Double
{
    [GlobalClass]
    public partial class DZeroLess : Forth.Words
    {
        public DZeroLess(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "D0<";
            Description =
                "Return true if and only if the double precision value d is less than zero.";
            StackEffect = "( d - flag )";
        }

        public override void Call()
        {
            if (Forth.PopDint() < 0)
            {
                Forth.Push(AMCForth.True);
            }
            else
            {
                Forth.Push(AMCForth.False);
            }
        }
    }
}
