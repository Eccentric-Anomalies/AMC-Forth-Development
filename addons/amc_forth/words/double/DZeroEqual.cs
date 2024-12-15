using Godot;

namespace Forth.Double
{
    [GlobalClass]
    public partial class DZeroEqual : Forth.Words
    {
        public DZeroEqual(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "D0=";
            Description =
                "Return true if and only if the double precision value d is equal to zero.";
            StackEffect = "( d - flag )";
        }

        public override void Call()
        {
            if (Forth.PopDint() == 0)
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
