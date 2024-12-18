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
                "Add a lookup entry for the IO port p, to execute 'word'. "
                + "Events to port p are enqueued with q mode (0, 1, 2), "
                + "where q = enqueue: 0 - always, 1 - if new value, 2 - replace all prior. "
                + "Note: An input port may have only one handler word.";
            StackEffect = "( 'word' p q - )";
        }

        public override void Call()
        {
            // Store the queue mode
            var q = Forth.Pop(); // queue mode
            var p = Forth.Pop(); // port number
            Forth.CoreWords.Tick.Call(); // retrieve XT for the handler (on stack)
            Forth.Push(AMCForth.IoInMapStart + p * 2 * ForthRAM.CellSize); // address of xt
            Forth.CoreWords.Store.Call(); // store the XT
            Forth.Push(q); // q mode
            Forth.Push(AMCForth.IoInMapStart + ForthRAM.CellSize * (p * 2 + 1)); // address of q mode
            Forth.CoreWords.Store.Call(); // store the Q mode
        }
    }
}
