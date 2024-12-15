using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Else : Forth.Words
    {
        public Else(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "ELSE";
            Description = "At compile time, originate the TRUE branch and and resolve the FALSE.";
            StackEffect = "( - )";
            Immediate = true;
        }

        public override void Call()
        {
            Forth.ToolsExtWords.Ahead.Call();
            Forth.CfStackRoll(1);
            Forth.CoreWords.Then.Call();
        }
    }
}
