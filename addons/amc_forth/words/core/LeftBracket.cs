using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class LeftBracket : Forth.Words
    {
        public LeftBracket(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "[";
            Description = "Enter interpretation state.";
            StackEffect = "( - )";
            Immediate = true;
        }

        public override void Call()
        {
            Forth.State = false;
        }
    }
}
