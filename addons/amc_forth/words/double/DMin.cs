using Godot;

namespace Forth.Double
{
    [GlobalClass]
    public partial class DMin : Forth.Words
    {
        public DMin(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "DMIN";
            Description = "Return d3, the lesser of d1 and d2.";
            StackEffect = "( d1 d2 - d3 )";
        }

        public override void Call()
        {
            var d2 = Forth.PopDint();
            if (d2 < Forth.GetDint(0))
            {
                Forth.SetDint(0, d2);
            }
        }
    }
}
