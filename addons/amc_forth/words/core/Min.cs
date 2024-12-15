using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Min : Forth.Words
    {
        public Min(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "MIN";
            Description = "Return n3, the lesser of n1 and n2.";
            StackEffect = "( n1 n2 - n3 )";
        }

        public override void Call()
        {
            var n2 = Forth.Pop();
            if (n2 < Forth.DataStack[Forth.DsP])
            {
                Forth.DataStack[Forth.DsP] = n2;
            }
        }
    }
}
