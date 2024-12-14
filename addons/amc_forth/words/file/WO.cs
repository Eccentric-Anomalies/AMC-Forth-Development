using Godot;

namespace Forth.File
{
    [GlobalClass]
    public partial class WO : Forth.Words
    {
        public WO(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "W/O";
            Description = "Return the write-only file access method.";
            StackEffect = "( - fam )";
        }

        public override void Call()
        {
            Forth.Push((int)FileAccess.ModeFlags.Write);
        }
    }
}
