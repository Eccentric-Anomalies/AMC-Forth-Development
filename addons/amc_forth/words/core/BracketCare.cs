using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class BracketCare : Forth.Words
    {
        public BracketCare(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "[CHAR]";
            Description =
                "Inside a colon definition, parse the following word and compile "
                + "the ASCII value of the first character as a literal. At run-time, "
                + "push the value on the stack.";
            StackEffect = "( - char )";
            Immediate = true;
        }

        public override void Call()
        {
            if (Forth.State)
            {
                Forth.CoreExtWords.ParseName.Call(); // get c-addr u
                Forth.CoreWords.Drop.Call(); // ignore length
                Forth.Ram.SetInt(Forth.DictTopP, XtX); // Store the exec token
                Forth.DictTopP += ForthRAM.CellSize;
                Forth.Push(Forth.Ram.GetByte(Forth.Pop())); // get first character byte
                Forth.CoreWords.CComma.Call(); // store it
                Forth.CoreWords.Align.Call();
                Forth.SaveDictTop(); // preserve dictionary state
            }
        }

        public override void CallExec()
        {
            // return LSB byte contents of cell after execution token
            Forth.Push(Forth.Ram.GetByte(Forth.DictIp + ForthRAM.CellSize));
            Forth.DictIp += ForthRAM.CellSize;
        }
    }
}
