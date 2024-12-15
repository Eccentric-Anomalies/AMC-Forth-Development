using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Repeat : Forth.Words
    {
        public Repeat(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "REPEAT";
            Description =
                "At compile time, resolve two branches, usually set up by BEGIN and WHILE. "
                + "At run-time, execute the unconditional backward branch to the location "
                + "following BEGIN.";
            StackEffect = "( - )";
            Immediate = true;
        }

        public override void Call()
        {
            Forth.CfStackRoll(1);
            Forth.CoreExtWords.Again.Call();
            Forth.CoreWords.Then.Call();
        }
    }
}
