using System;
using Godot;

namespace Forth.AMCExt
{
    [GlobalClass]
    public partial class PTimer : Forth.Words
    {
        public PTimer(AMCForth forth, string wordset)
            : base(forth, wordset)
        {
            Name = "P-TIMER";
            Description =
                "Start a periodic timer with id i, and interval n (msec) that "
                + "calls execution token given by <name>. Does nothing if the id "
                + "is in use. Usage: <id> <msec> P-TIMER <name>";
            StackEffect = "( 'name' i n - )";
        }

        public override void Call()
        {
            Forth.CoreWords.Swap.Call();
            // ( i n - n i )
            Forth.CoreWords.Dup.Call();
            // ( n i - n i i )
            var id = Forth.Pop();
            // ( n i i - n i )
            GetTimerAddress();
            // ( n i - n addr )
            Forth.CoreWords.Tick.Call();
            // ( n addr - n addr xt )
            var xt = Forth.Pop();
            var addr = Forth.Pop();
            var ms = Forth.Pop();
            // ( - )
            try
            {
                if ((ms != 0) && (Forth.Ram.GetInt(addr) == 0))
                {
                    // only if non-zero and nothing already there
                    Forth.Ram.SetInt(addr, ms);
                    Forth.Ram.SetInt(addr + ForthRAM.CellSize, xt);
                    Forth.StartPeriodicTimer(id, ms, xt);
                }
            }
            catch (ArgumentOutOfRangeException)
            {
                Forth.Util.RprintTerm(
                    $" Timer ID out of range (maximum {AMCForth.PeriodicTimerQty})."
                );
            }
        }

        public void GetTimerAddress()
        {
            // Utility to accept timer id and leave the start address of
            // its msec, xt pair
            // ( id - addr )
            Forth.Push(ForthRAM.CellSize);
            Forth.CoreWords.TwoStar.Call();
            Forth.CoreWords.Star.Call();
            Forth.Push(AMCForth.PeriodicStart);
            Forth.CoreWords.Plus.Call();
        }
    }
}
