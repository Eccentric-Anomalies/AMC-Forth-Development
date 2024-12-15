using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class Listen : Forth.Words
    {
        public Listen(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "LISTEN";
            Description =
                "Add a lookup entry for the IO port p, to execute <word>. "
                + "Usage: <port> LISTEN . ( prints port value when received )";
            StackEffect = "( 'word' p - )";
        }

        public override void Call()
        {
            // convert port to address
            GetPortAddress();
            Forth.CoreWords.Tick.Call();
            // get the xt of the following word
            Forth.CoreWords.Swap.Call();
            Forth.CoreWords.Store.Call();
        }

        public void GetPortAddress()
        {
            // Utility to accept port number and leave its address
            // in the handler table.
            // ( p - addr )
            Forth.Push(ForthRAM.CellSize);
            Forth.CoreWords.Star.Call();
            Forth.Push(AMCForth.IoInMapStart);
            Forth.CoreWords.Plus.Call();
        }
    }
}
