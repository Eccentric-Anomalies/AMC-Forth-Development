using Godot;
using Godot.Collections;

// @WORDSET AMC Extended

//


// Initialize (executed automatically by ForthAMCExt.new())
//
// (1) All functions with "## @WORD <word>" comment will become
// the default implementation for the built-in word.
// (2) All functions with "## @WORDX <word>" comment will become
// the *compiled* implementation for the built-in word.
// (3) Define an IMMEDIATE function with "## @WORD <word> IMMEDIATE"
// (4) UP TO four comments beginning with "##" before function
// (5) Final comment must be "## @STACK" followed by stack def.
[GlobalClass]
public partial class ForthAMCExt : ForthImplementationBase
{
	public override void Initialize(AMCForth _forth)
	{
		Super(_forth);


	// @WORD BLINKV
	// Send BLINK command to video terminal.

	}// @STACK ( - )
	public void BlinkV()
	{
		Forth.Util.PrintTerm(ForthTerminal.BLINK);
	}

	// @WORD BOLDV
	// Send BOLD command to video terminal.
	// @STACK ( - )
	public void BoldV()
	{
		Forth.Util.PrintTerm(ForthTerminal.BOLD);
	}


	protected void _GetPortAddress()
	{
		// Utility to accept port number and leave its address
		// in the handler table.
		// ( p - addr )
		Forth.Push(ForthRAM.CELL_SIZE);
		Forth.Core.Star();
		Forth.Push(Forth.IO_IN_MAP_START);
		Forth.Core.Plus();
	}


// helper function for retrieving the next word
	protected string _NextWord()
	{
		// retrieve the name token
		Forth.CoreExt.ParseName();
		var len = Forth.Pop();
		// length
		var caddr = Forth.Pop();
		// start
		return Forth.Util.StrFromAddrN(caddr, len);
	}

	// @WORD HELP
	// Display the description for the following Forth built-in word.
	// @STACK ( "name" - )
	public void Help()
	{
		Forth.Util.PrintTerm(" " + Forth.WordDescription.Get(_NextWord(), "(not found)"));
	}

	// @WORD HELPS
	// Display stack definition for the following Forth word.
	// @STACK ( "name" - )
	public void HelpS()
	{
		Forth.Util.PrintTerm(" " + Forth.WordStackdef.Get(_NextWord(), "(not found)"));
	}

	// @WORD HELPWS
	// Display word set for the following Forth word.
	// @STACK ( "name" - )
	public void HelpWS()
	{
		Forth.Util.PrintTerm(" " + Forth.WordWordset.Get(_NextWord(), "(not found)"));
	}

	// @WORD INVISIBLEV
	// Send INVISIBLE command to video terminal.
	// @STACK ( - )
	public void InvisibleV()
	{
		Forth.Util.PrintTerm(ForthTerminal.INVISIBLE);
	}

	// @WORD LISTEN
	// Add a lookup entry for the IO port p, to execute <word>.
	// Usage: <port> LISTEN . ( prints port value when received )
	// @STACK ( "word" p - )
	public void Listen()
	{
		// convert port to address
		_GetPortAddress();
		Forth.Core.Tick();
		// get the xt of the following word
		Forth.Core.Swap();
		Forth.Core.Store();
	}

	// @WORD LOAD-SNAP
	// Restore the Forth system RAM from backup file.
	// @STACK ( - )
	public void LoadSnap()
	{
		Forth.LoadSnapshot();
	}

	// @WORD LOWV
	// Send LOWINT (low intensity) command to video terminal.
	// @STACK ( - )
	public void LowV()
	{
		Forth.Util.PrintTerm(ForthTerminal.LOWINT);
	}


	protected void _GetTimerAddress()
	{
		// Utility to accept timer id and leave the start address of
		// its msec, xt pair
		// ( id - addr )
		Forth.Push(ForthRAM.CELL_SIZE);
		Forth.Core.TwoStar();
		Forth.Core.Star();
		Forth.Push(Forth.PERIODIC_START);
		Forth.Core.Plus();
	}

	// @WORD NOMODEV
	// Send MODESOFF command to video terminal.
	// @STACK ( - )
	public void NomodeV()
	{
		Forth.Util.PrintTerm(ForthTerminal.MODESOFF);
	}

	// @WORD OUT
	// Save value x to I/O port p, possibly triggering Godot signal.
	// @STACK ( x p - )
	public void Out()
	{
		Forth.Core.Dup();
		var port = Forth.Pop();
		Forth.Core.Cells();
		// offset in bytes
		Forth.Push(AMCForth.IO_OUT_START);
		// address of output block
		Forth.Core.Plus();
		// output address
		Forth.Core.Over();
		// copy value
		var value = Forth.Pop();
		Forth.Core.Store();
		if(Forth.OutputPortMap.Contains(port))
		{
			var sig = Forth.OutputPortMap[port];
			CallDeferred("_output_emitter", port, value);
		}
	}


	protected void _OutputEmitter(int port, int value)
	{
		Forth.OutputPortMap[port].Emit(value);
	}

	// @WORD P-TIMER
	// Start a periodic timer with id i, and interval n (msec) that
	// calls execution token given by <name>. Does nothing if the id
	// is in use. Usage: <id> <msec> P-TIMER <name>
	// @STACK ( "name" i n - )
	public void PTimer()
	{
		Forth.Core.Swap();
		// ( i n - n i )
		Forth.Core.Dup();
		// ( n i - n i i )
		var id = Forth.Pop();
		// ( n i i - n i )
		_GetTimerAddress();
		// ( n i - n addr )
		Forth.Core.Tick();
		// ( n addr - n addr xt )
		var xt = Forth.Pop();
		var addr = Forth.Pop();
		var ms = Forth.Pop();
		// ( - )
		if(ms && !Forth.Ram.GetInt(addr))
		{
			// only if non-zero and nothing already there
			Forth.Ram.SetInt(addr, ms);
			Forth.Ram.SetInt(addr + ForthRAM.CELL_SIZE, xt);
			Forth.StartPeriodicTimer(id, ms, xt);
		}
	}

	// @WORD P-STOP
	// Stop periodic timer with id i.
	// @STACK ( i - )
	public void PStop()
	{
		_GetTimerAddress();
		// ( i - addr )
		var addr = Forth.Pop();
		// ( addr - )
		// clear the entries for the given timer id
		Forth.Ram.SetInt(addr, 0);
		Forth.Ram.SetInt(addr + ForthRAM.CELL_SIZE, 0);
		// the next time this timer expires, the system will find nothing
		// here for the ID, and it will be cancelled.
	}

	// @WORD POP-XY
	// Configure output device so next character display will appear
	// at the column and row that were last saved with PUSH-XY.
	// @STACK ( - )
	public void PopXY()
	{
		Forth.Util.PrintTerm(ForthTerminal.ESC + "8");
	}

	// @WORD PUSH-XY
	// Tell the output device to save its current output position, to
	// be retrieved later using POP-XY.
	// @STACK ( - )
	public void PushXY()
	{
		Forth.Util.PrintTerm(ForthTerminal.ESC + "7");
	}

	// @WORD REVERSEV
	// Send REVERSE command to video terminal.
	// @STACK ( - )
	public void ReverseV()
	{
		Forth.Util.PrintTerm(ForthTerminal.REVERSE);
	}

	// @WORD SAVE-SNAP
	// Save the Forth system RAM to backup file.
	// @STACK ( - )
	public void SaveSnap()
	{
		Forth.SaveSnapshot();
	}

	// @WORD UNDERLINEV
	// Send UNDERLINE command to video terminal.
	// @STACK ( - )
	public void UnderlineV()
	{
		Forth.Util.PrintTerm(ForthTerminal.UNDERLINE);
	}

	// @WORD UNLISTEN
	// Remove a lookup entry for the IO port p.
	// @STACK ( p - )
	public void Unlisten()
	{
		_GetPortAddress();
		Forth.Push(0);
		Forth.Core.Swap();
		Forth.Core.Store();
	}

}
