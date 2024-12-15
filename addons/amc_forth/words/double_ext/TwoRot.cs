using Godot;

namespace Forth.DoubleExt
{
    [GlobalClass]
    public partial class TwoRot : Forth.Words
    {
        public TwoRot(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "2ROT";
            Description = "Rotate the top three cell pairs on the stack.";
            StackEffect = "( x1 x2 x3 x4 x5 x6 - x3 x4 x5 x6 x1 x2 )";
        }

        public override void Call()
        {
            var t = Forth.GetDint(4);
            Forth.SetDint(4, Forth.GetDint(2));
            Forth.SetDint(2, Forth.GetDint(0));
            Forth.SetDint(0, t);
        }
    }
}
