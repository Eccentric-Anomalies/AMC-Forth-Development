using Godot;

namespace Forth.Double
{
    [GlobalClass]
    public partial class MPlus : Forth.Words
    {
        public MPlus(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "M+";
            Description = "Add n to d1 leaving the sum d2.";
            StackEffect = "( d1 n - d2 )";
        }

        public override void Call()
        {
            var n = Forth.Pop();
            Forth.PushDint(Forth.PopDint() * n);
        }
    }
}
