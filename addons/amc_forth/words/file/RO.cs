using Godot;

namespace Forth.File
{
    [GlobalClass]
    public partial class RO : Forth.Words
    {
        public RO(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "R/O";
            Description = "Return the read-only file access method.";
            StackEffect = "( - fam )";
        }

        public override void Call()
        {
            Forth.Push((int)FileAccess.ModeFlags.Read);
        }
    }
}
