using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class BufferColon : Forth.Words
    {
        public BufferColon(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "BUFFER:";
            Description =
                "Create a dictionary entry for <name>, associated with n bytes of space. "
                + "Usage: <n> BUFFER: <name> "
                + "Executing <name> will return address of the starting byte on the stack.";
            StackEffect = "( 'name' n - )";
        }

        public override void Call()
        {
            Forth.CoreWords.Create.Call();
            Forth.CoreWords.Allot.Call();
        }
    }
}
