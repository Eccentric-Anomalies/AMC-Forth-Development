using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class I : Forth.Words
    {
        public I(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "I";
            Description = "Push a copy of the current DO-LOOP index value to the stack.";
            StackEffect = "( - n )";
        }

        public override void Call()
        {
            Forth.CoreWords.RFetch.Call();
        }
    }
}
