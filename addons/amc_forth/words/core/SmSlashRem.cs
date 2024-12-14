using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class SmSlashRem : Forth.Words
    {
        public SmSlashRem(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "SM/REM";
            Description =
                "Divide d by n1, using symmetric division, giving quotient n3 and "
                + "remainder n2. All arguments are signed.";
            StackEffect = "( d n1 - n2 n3 )";
        }

        public override void Call()
        {
            var n1 = Forth.Pop();
            var d = Forth.PopDint();
            Forth.Push((int)(d % n1));
            Forth.Push((int)(d / n1));
        }
    }
}
