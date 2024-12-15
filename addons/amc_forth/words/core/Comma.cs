using Godot;

namespace Forth.Core
{
    [GlobalClass]
    public partial class Comma : Forth.Words
    {
        public Comma(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = ",";
            Description = "Reserve one cell of data space and store x in it.";
            StackEffect = "( x - )";
        }

        public override void Call()
        {
            Forth.Ram.SetInt(Forth.DictTopP, Forth.Pop());
            Forth.DictTopP += ForthRAM.CellSize;
            Forth.SaveDictTop(); // preserve dictionary state
        }
    }
}
