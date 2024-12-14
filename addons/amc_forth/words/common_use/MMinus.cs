using Godot;

namespace Forth.CommonUse
{
    [GlobalClass]
    public partial class MMinus : Forth.Words
    {
        public MMinus(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "M-";
            Description = "Subtract n from d1 leaving the difference d2.";
            StackEffect = "( d1 n - d2 )";
        }

        public override void Call()
        {
            var n = Forth.Pop();
            Forth.PushDint(Forth.PopDint() - n);
        }
    }
}
