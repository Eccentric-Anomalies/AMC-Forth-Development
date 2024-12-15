using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Literal : Forth.Words
    {
        public Literal(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "LITERAL";
            Description =
                "At execution time, remove the top number from the stack and compile "
                + "into the current definition. Upon executing <name>, place the "
                + "number on the top of the stack.";
            StackEffect = "Compile:  ( x - ), Execute: ( - x )";
            Immediate = true;
        }

        public override void Call()
        {
            var literal_val = Forth.Pop();
            // copy the execution token
            Forth.Ram.SetInt(Forth.DictTopP, XtX);
            // store the value
            Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, literal_val);
            Forth.DictTopP += ForthRAM.DCellSize;
            // two cells up
            // preserve dictionary state
            Forth.SaveDictTop();
        }

        public override void CallExec()
        {
            // execution time functionality of literal
            // return contents of cell after execution token
            Forth.Push(Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize));
            // advance the instruction pointer by one to skip over the data
            Forth.DictIp += ForthRAM.CellSize;
        }
    }
}
