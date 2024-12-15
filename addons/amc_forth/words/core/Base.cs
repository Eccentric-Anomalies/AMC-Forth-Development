using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Base : Forth.Words
    {
        public Base(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "BASE";
            Description =
                "Return a-addr, the address of a cell containing the current number "
                + "conversion radix, between 2 and 36 inclusive.";
            StackEffect = "( - a-addr )";
        }

        public override void Call()
        {
            Forth.Push(AMCForth.Base);
        }
    }
}
