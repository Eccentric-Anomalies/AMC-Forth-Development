using System;
using Godot;

namespace Forth.CommonUse
{
    [GlobalClass]
    public partial class MSlash : Forth.Words
    {
        public MSlash(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "M/";
            Description = "Divide d by n1 leaving the single precision quotient n2.";
            StackEffect = "( d n1 - n2 )";
        }

        public override void Call()
        {
            var n = Forth.Pop();
            Forth.Push(Convert.ToInt32((Forth.PopDint() / n) & UInt32.MaxValue));
        }
    }
}
