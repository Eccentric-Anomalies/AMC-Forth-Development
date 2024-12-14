using Godot;

namespace Forth.Double
{
    [GlobalClass]
    public partial class DEquals : Forth.Words
    {
        public DEquals(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "D=";
            Description = "Return true if and only if d1 is equal to d2.";
            StackEffect = "( d1 d2 - flag )";
        }

        public override void Call()
        {
            var t = Forth.PopDint();
            if (Forth.PopDint() == t)
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
