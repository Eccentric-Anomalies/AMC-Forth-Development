using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class ToIn : Forth.Words
    {
        public ToIn(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = ">IN";
            Description =
                "Return address of a cell containing the offset, in characters, "
                + "from the start of the input buffer to the start of the current "
                + "parse position.";
            StackEffect = "( - a-addr )";
        }

        public override void Call()
        {
            // terminal pointer or...
            if (Forth.SourceId == -1)
            {
                Forth.Push(AMCForth.BuffToIn);
            }
            // file buffer pointer
            else if (Forth.SourceId != 0)
            {
                Forth.Push(Forth.SourceId + AMCForth.FileBuffPtrOffset);
            }
        }
    }
}
