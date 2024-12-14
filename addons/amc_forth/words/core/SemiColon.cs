using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class SemiColon : Forth.Words
    {
        public SemiColon(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = ";";
            Description = "Leave compilation state.";
            StackEffect = "( - )";
            Immediate = true;
        }

        public override void Call()
        {
            // remove the smudge bit
            Forth.Ram.SetByte(
                Forth.CoreWords.Colon.SmudgeAddress,
                Forth.Ram.GetByte(Forth.CoreWords.Colon.SmudgeAddress) & ~AMCForth.SmudgeBitMask
            );
            Forth.State = false; // clear compile state
            Forth.Ram.SetInt(Forth.DictTopP, XtX);
            Forth.DictTopP += ForthRAM.CellSize;
            Forth.SaveDictTop(); // preserve dictionary state
            // check for control flow stack integrity
            if (!Forth.CfStackIsEmpty())
            {
                Forth.Util.RprintTerm("Unbalanced control structure");
                Forth.UnwindCompile();
            }
        }

        public override void CallExec()
        {
            Forth.CoreWords.Exit.Call();
        }
    }
}
