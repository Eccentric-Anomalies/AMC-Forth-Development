using Godot;

namespace Forth.CoreExt
{
    [GlobalClass]
    public partial class To : Forth.Words
    {
        public To(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "TO";
            Description =
                "Store x in the data space associated with name (defined with VALUE). "
                + "Usage: <x> TO <name>";
            StackEffect = "( 'name' x - )";
            Immediate = true;
        }

        public override void Call()
        {
            // get the name
            Forth.CoreExtWords.ParseName.Call();
            var len = Forth.Pop(); // length
            var caddr = Forth.Pop(); // start
            var word = Forth.Util.StrFromAddrN(caddr, len);
            var token_addr_immediate = Forth.FindInDict(word);
            if (token_addr_immediate.Addr != 0)
            {
                Forth.Util.PrintUnknownWord(word);
            }
            else
            {
                if (Forth.State)
                {
                    // Compiling
                    // Copy the execution token
                    Forth.Ram.SetInt(Forth.DictTopP, XtX);
                    // Copy the address of the VALUE
                    int destaddr = token_addr_immediate.Addr + ForthRAM.CellSize;
                    Forth.Ram.SetInt(Forth.DictTopP + ForthRAM.CellSize, destaddr);
                    Forth.DictTopP += ForthRAM.DCellSize; // two cells up and done
                    Forth.SaveDictTop(); // preserve the state
                }
                else
                {
                    // not compiling
                    // poke top of stack into the memory
                    Forth.Ram.SetInt(token_addr_immediate.Addr + ForthRAM.CellSize, Forth.Pop());
                }
            }
        }

        public override void CallExec()
        {
            // compiled execution time functionality of TO
            // Set the TO location from top of stack
            Forth.Ram.SetInt(Forth.Ram.GetInt(Forth.DictIp + ForthRAM.CellSize), Forth.Pop());
            Forth.DictIp += ForthRAM.CellSize;
        }
    }
}
