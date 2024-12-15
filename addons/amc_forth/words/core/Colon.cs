using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Colon : Forth.Words
    {
        public int SmudgeAddress;

        public Colon(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = ":";
            Description = "Create a definition for <name> and enter compilation state.";
            StackEffect = "( 'name' - )";
        }

        public override void Call()
        {
            SmudgeAddress = Forth.CreateDictEntryName(true);
            if (SmudgeAddress != 0)
            {
                Forth.State = true; // enter compile state
                Forth.Ram.SetInt(Forth.DictTopP, XtX);
                Forth.DictTopP += ForthRAM.CellSize;
                // preserve dictionary state
                Forth.SaveDictTop();
            }
        }

        public override void CallExec()
        {
            // Execution behavior of colon
            // save the current stack level
            while (!Forth.ExitFlag)
            {
                Forth.DictIp += ForthRAM.CellSize; // Step to the next item
                Forth.Push(Forth.Ram.GetInt(Forth.DictIp)); // get the next execution token
                Forth.CoreWords.Execute.Call(); // and do what it says to do!
            }
            Forth.ExitFlag = false; // We are exiting. Reset the flag.
        }
    }
}
