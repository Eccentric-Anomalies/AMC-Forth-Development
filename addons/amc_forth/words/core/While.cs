using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class While : Forth.Words
    {
        public While(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "WHILE";
            Description =
                "At compile time, place a new unresolved forward reference origin on the "
                + "control stack. At run-time, if x is zero, take the forward branch to the "
                + "destination supplied by REPEAT.";
            StackEffect = "( - )";
            Immediate = true;
        }

        public override void Call()
        {
            Forth.CoreWords.If.Call();
        }
    }
}
