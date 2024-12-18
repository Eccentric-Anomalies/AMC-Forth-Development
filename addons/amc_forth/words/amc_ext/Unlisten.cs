using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class Unlisten : Forth.Words
    {
        public Unlisten(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "UNLISTEN";
            Description = "Remove a lookup entry for the IO port p.";
            StackEffect = "( p - )";
        }

        public override void Call()
        {
            var p = Forth.Pop(); // port number
            Forth.Push(0);
            Forth.Push(AMCForth.IoInMapStart + p * 2 * ForthRAM.CellSize); // address of xt
            Forth.CoreWords.Store.Call(); // store the XT
            Forth.Push(0);
            Forth.Push(AMCForth.IoInMapStart + ForthRAM.CellSize * (p * 2 + 1)); // address of q mode
            Forth.CoreWords.Store.Call(); // store the Q mode
        }
    }
}
