using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class ULessThan : Forth.Words
    {
        public ULessThan(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "U>";
            Description = "Return true if and only if u1 is greater than u2.";
            StackEffect = "( u1 u2 - flag )";
        }

        public override void Call()
        {
            var u2 = (uint)Forth.Pop();
            if ((uint)Forth.Pop() > u2)
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
