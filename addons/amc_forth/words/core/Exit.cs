using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Exit : Forth.Words
    {
        public Exit(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "EXIT";
            Description = "Return control to the calling definition in the ip-stack.";
            StackEffect = "( - )";
        }

        public override void Call()
        {
            Forth.ExitFlag = true; // set a flag indicating exit has been called
        }
    }
}
