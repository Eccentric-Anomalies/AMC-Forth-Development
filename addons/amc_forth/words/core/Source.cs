using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Source : Forth.Words
    {
        public Source(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "SOURCE";
            Description = "Return the address and length of the input buffer.";
            StackEffect = "( - c-addr u )";
        }

        public override void Call()
        {
            if (Forth.SourceId == -1)
            {
                Forth.Push(AMCForth.BuffSourceStart);
                Forth.Push(AMCForth.BuffSourceSize);
            }
            else if (Forth.SourceId != 0)
            {
                Forth.Push(Forth.SourceId + AMCForth.FileBuffDataOffset);
                Forth.Push(AMCForth.FileBuffDataSize);
            }
        }
    }
}
