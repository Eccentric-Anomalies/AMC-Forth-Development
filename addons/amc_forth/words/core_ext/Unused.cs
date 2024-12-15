using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class Unused : Forth.Words
    {
        public Unused(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "UNUSED";
            Description =
                "Return u, the number of bytes remaining in the memory area "
                + "where dictionary entries are constructed.";
            StackEffect = "( - u )";
        }

        public override void Call()
        {
            Forth.Push(AMCForth.DictTop - Forth.DictTopP);
        }
    }
}
