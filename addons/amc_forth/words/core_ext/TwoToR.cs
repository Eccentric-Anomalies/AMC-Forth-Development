using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class TwoToR : Forth.Words
    {
        public TwoToR(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "2>R";
            Description =
                "Pop the top two cells from the data stack and push them onto the "
                + "return stack.";
            StackEffect = "(S: x1 x2 - )  (R: - x1 x2 )";
        }

        public override void Call()
        {
            Forth.RPushDint(Forth.PopDint());
        }
    }
}
