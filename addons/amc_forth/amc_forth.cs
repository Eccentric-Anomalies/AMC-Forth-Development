using Godot;
using Godot.Collections;

[GlobalClass]
public partial class AMCForth : Godot.RefCounted
{
	[Signal]
	public delegate void TerminalOutEventHandler(string text);
	[Signal]
	public delegate void TerminalInReadyEventHandler();


	// control flow address types
	public enum Enum0 {ORIG, DEST}

	public const string BANNER = "AMC Forth";
	public const string CONFIG_FILE_NAME = "user://ForthState.cfg";


	// Memory Map
	public const int RAM_SIZE = 0x10000;
	// BYTES
	// Dictionary
	public const int DICT_START = 0x0100;
	// BYTES
	public const int DICT_SIZE = 0x08000;
	public const int DICT_TOP = DICT_START + DICT_SIZE;

	// Dictionary scratch space
	public const int DICT_BUFF_SIZE = 0x040;
	// word-sized
	public const int DICT_BUFF_START = DICT_TOP;
	public const int DICT_BUFF_TOP = DICT_BUFF_START + DICT_BUFF_SIZE;

	// Input Buffer
	public const int BUFF_SOURCE_SIZE = 0x0100;
	// bytes
	public const int BUFF_SOURCE_START = DICT_BUFF_TOP;
	public const int BUFF_SOURCE_TOP = BUFF_SOURCE_START + BUFF_SOURCE_SIZE;

	// File Buffers
	public const int FILE_BUFF_QTY = 8;
	// number of simultaneous open files possible
	public const int FILE_BUFF_ID_OFFSET = 0;
	// offset in buffer to fileid
	public const int FILE_BUFF_PTR_OFFSET = ForthRAM.CELL_SIZE;
	// location of pointer
	public const int FILE_BUFF_DATA_OFFSET = ForthRAM.CELL_SIZE * 2;
	// location of buff data
	public const int FILE_BUFF_SIZE = 0x0100;
	// bytes, overall
	public const int FILE_BUFF_DATA_SIZE = FILE_BUFF_SIZE - FILE_BUFF_DATA_OFFSET;
	public const int FILE_BUFF_START = BUFF_SOURCE_TOP;
	public const int FILE_BUFF_TOP = FILE_BUFF_START + FILE_BUFF_SIZE * FILE_BUFF_QTY;

	// Pointer to the parse position in the TERMINAL buffer
	public const int BUFF_TO_IN = FILE_BUFF_TOP;
	public const int BUFF_TO_IN_TOP = BUFF_TO_IN + ForthRAM.CELL_SIZE;

	// Temporary word storage (used by WORD)
	public const int WORD_SIZE = 0x0100;
	public const int WORD_START = BUFF_TO_IN_TOP;
	public const int WORD_TOP = WORD_START + WORD_SIZE;

	// BASE cell
	public const int BASE = WORD_TOP;

	// DICT_TOP_PTR cell
	public const int DICT_TOP_PTR = BASE + ForthRAM.CELL_SIZE;

	// DICT_PTR
	public const int DICT_PTR = DICT_TOP_PTR + ForthRAM.CELL_SIZE;


	// IO SPACE - cell-sized ports identified by port # ranging from 0 to 255
	public const int IO_OUT_PORT_QTY = 0x0100;
	public const int IO_OUT_TOP = RAM_SIZE;
	public const int IO_OUT_START = IO_OUT_TOP - IO_OUT_PORT_QTY * ForthRAM.CELL_SIZE;
	public const int IO_IN_PORT_QTY = 0x0100;
	public const int IO_IN_TOP = IO_OUT_START;
	public const int IO_IN_START = IO_IN_TOP - IO_IN_PORT_QTY * ForthRAM.CELL_SIZE;
	public const int IO_IN_MAP_TOP = IO_IN_START;

	// xt for every port that is being listened on
	public const int IO_IN_MAP_START = IO_IN_MAP_TOP - IO_IN_PORT_QTY * ForthRAM.CELL_SIZE;

	// PERIODIC TIMER SPACE
	public const int PERIODIC_TIMER_QTY = 0x080;
	// Timer IDs 0-127, stored as @addr: msec, xt
	public const int PERIODIC_TOP = IO_IN_START;


	public const int PERIODIC_START = (PERIODIC_TOP - PERIODIC_TIMER_QTY * ForthRAM.CELL_SIZE * 2);


	// Add more pointers here
	public const int TRUE = - 1;
	public const int FALSE = 0;

	public const int MAX_BUFFER_SIZE = 20;

	public const int DATA_STACK_SIZE = 100;
	public const int DATA_STACK_TOP = DATA_STACK_SIZE - 1;

	public const int RETURN_STACK_SIZE = 100;
	public const int RETURN_STACK_TOP = RETURN_STACK_SIZE - 1;


	// Masks for built-in execution tokens
	public const int UNUSED_MASK = ~ 0x7FFFFFFF;
	public const int BUILT_IN_XT_MASK = 0x040000000;
	public const int BUILT_IN_XTX_MASK = 0x020000000;

	// Ensure we don't generate tokens that are larger than the CELL_SIZE


	public const int BUILT_IN_MASK =  ~ (UNUSED_MASK | BUILT_IN_XT_MASK | BUILT_IN_XTX_MASK);
	
// Smudge bit mask
	public const int SMUDGE_BIT_MASK = 0x80;

	// Immediate bit mask
	public const int IMMEDIATE_BIT_MASK = 0x40;

	// Largest name length
	public const int MAX_NAME_LENGTH = 0x3f;


	// Reference to the physical memory and utilities
	public ForthRAM Ram;
	public ForthUtil Util;

	// Core Forth word implementations
	public ForthCore Core;
	public ForthCoreExt CoreExt;
	public ForthTools Tools;
	public ForthToolsExt ToolsExt;
	public ForthCommonUse CommonUse;
	public ForthDouble Double;
	public ForthDoubleExt DoubleExt;
	public ForthString FString;
	public ForthAMCExt AmcExt;
	public ForthFacility Facility;
	public ForthFileExt FileExt;
	public ForthFile File;


	// Forth built-in meta-data
	public Dictionary WordDescription = new Dictionary{};
	public Dictionary WordStackdef = new Dictionary{};
	public Dictionary WordWordset = new Dictionary{};
	public Dictionary WordsetWords = new Dictionary{};


	// The Forth data stack pointer is in byte units
	// The Forth dictionary space
	public int DictP;
	// position of last link
	public int DictTop;
	// position of next new link to create
	public int DictIp = 0;

	// code field pointer set to current execution point
	// Forth compile state
	public bool State = false;


	// Forth source ID
	public int SourceId = 0;
	// 0 default, -1 ram buffer, else file id
	public Array SourceIdStack = new Array{};


	// Built-In names have a run-time definition
	// These are "<WORD>", <run-time function> pairs that are defined by each
	// Forth implementation class (e.g. ForthDouble, etc.)
	public Array BuiltInNames = new Array{};

	// list of built-in functions that have different
	// compiled (execution token) behavior.
	// These are <run-time function> items that are defined by each
	// Forth implementation class (e.g. ForthDouble, etc.) when a
	// different *compiled* behavior is required
	// Each item is a [<name>, <callable>] pair
	public Array BuiltInExecFunctions = new Array{};

	// List of built-in names that are IMMEDIATE by default
	public Array ImmediateNames = new Array{};


	// get "address" from built-in function
	public Dictionary AddressFromBuiltInFunction = new Dictionary{};

	// get built-in function from "address"
	public Dictionary BuiltInFunctionFromAddress = new Dictionary{};

	// get built-in function from word
	public Dictionary BuiltInFunction = new Dictionary{};


	// Forth : exit flag (true if exit has been called)
	public bool ExitFlag = false;


	// Forth: data stack
	public int[] DataStack;
	public int DsP;


	// Forth: return stack
	public int[] ReturnStack;
	public int RsP;


	// Output handlers
	public Dictionary OutputPortMap = new Dictionary{};

	// Input event list
	public Array InputPortEvents = new Array{};

	// Periodic timer list
	public Dictionary PeriodicTimerMap = new Dictionary{};

	// Timer events queue
	public Array TimerEvents = new Array{};


	// Owning Node
	protected Godot.Variant _Node;


	// State file
	protected Godot.ConfigFile _Config;

	protected bool _DataStackUnderflow = false;


	// terminal scratchpad and buffer
	protected string _TerminalPad = "";
	protected int _PadPosition = 0;
	protected int _ParsePointer = 0;
	protected Array _TerminalBuffer = new Array{};
	protected int _BufferIndex = 0;


	// Forth : execution dict_ip stack
	protected Array _DictIpStack = new Array{};


	// Forth: control flow stack. Entries are in the form
	// [orig | dest, address]
	protected Array _ControlFlowStack = new Array{};


	// Forth: loop control flow stack for LEAVE ORIG entries only!
	protected Array _LeaveControlFlowStack = new Array{};


	// Thread data
	protected System.Threading.Thread _Thread;
	protected Godot.Semaphore _InputReady;
	protected bool _OutputDone;


	// Client connect count
	protected int _ClientConnections = 0;


	// File access
	// map Forth fileid to FileAccess objects
	// file_id is the address of the file's buffer structure
	// the first cell in the structure is the file access mode bits
	protected Dictionary _FileIdDict = new Dictionary{};


	// allocate a buffer for the provided file handle and mode
	// return the file id or zero if none available
	public int AssignFileId(Godot.FileAccess file, int new_mode)
	{
		foreach(int i in FILE_BUFF_QTY)
		{
			var addr = i * FILE_BUFF_SIZE + FILE_BUFF_START;
			var mode = Ram.GetInt(addr + FILE_BUFF_ID_OFFSET);
			if(mode == 0)
			{

				// available file handle
				Ram.SetInt(addr + FILE_BUFF_ID_OFFSET, new_mode);
				Ram.SetInt(addr + FILE_BUFF_PTR_OFFSET, 0);
				_FileIdDict[addr] = File;
				return addr;
			}
			addr += FILE_BUFF_SIZE;
		}
		return 0;
	}


	public Godot.FileAccess GetFileFromId(int id)
	{
		return _FileIdDict.Get(id, null);
	}


// releases an file buffer, and closes the associated file, if open
	public void FreeFileId(int id)
	{
		var file = _FileIdDict[id];
		if(File.IsOpen())
		{
			File.Close();
		}

	// clear the buffer entry
		Ram.SetInt(id + FILE_BUFF_ID_OFFSET, 0);

		// erase the dictionary entry
		_FileIdDict.Erase(id);
	}


	public void ClientConnected()
	{
		if(!_ClientConnections)
		{
			EmitSignal("TerminalOut", _GetBanner() + ForthTerminal.CRLF);
			_ClientConnections += 1;
		}
	}


	public void CloseAllFiles()
	{
		foreach(Dictionary id in _FileIdDict)
		{
			FreeFileId(id);
		}
	}


// pause until Forth is ready to accept inupt
	public bool IsReadyForInput()
	{
		return _OutputDone;
	}


// preserve Forth memory and state
	public void SaveSnapshot()
	{
		_Config.Clear();
		CloseAllFiles();
		Ram.SaveState(_Config);
		_Config.Save(CONFIG_FILE_NAME);
	}


// restore Forth memory and state
	public void LoadSnapshot()
	{

		// stop all periodic timers
		_RemoveAllTimers();

		// if a timer comes in, it should see nothing to do
		_Config.Load(CONFIG_FILE_NAME);
		Ram.LoadState(_Config);

		// restore shadowed registers
		RestoreDictP();
		RestoreDictTop();

		// start all configured periodic timers
		_RestoreAllTimers();
	}


// handle editing input strings in interactive mode
	public void TerminalIn(string text)
	{
		var in_str = text;
		var echo_text = "";
		var buffer_size = _TerminalBuffer.Size();
		while(in_str.Length() > 0)
		{
			if(in_str.Find(ForthTerminal.DEL_LEFT) == 0)
			{
				_PadPosition = Mathf.Max(0, _PadPosition - 1);
				if(_TerminalPad.Length())
				{

					// shrink if deleting from end, else replace with space
					if(_PadPosition == _TerminalPad.Length() - 1)
					{
						_TerminalPad = _TerminalPad.Left(_PadPosition);
					}
					else
					{
						_TerminalPad[_PadPosition] = " ";
					}
				}

		// reconstruct the changed entry, with correct cursor position
				echo_text = _RefreshEditText();
				in_str = in_str.Erase(0, ForthTerminal.DEL_LEFT.Length());
			}
			else if(in_str.Find(ForthTerminal.DEL) == 0)
			{

				// do nothing unless cursor is in text
				if(_PadPosition <= _TerminalPad.Length())
				{
					_TerminalPad = _TerminalPad.Erase(_PadPosition);
				}

			// reconstruct the changed entry, with correct cursor position
				echo_text = _RefreshEditText();
				in_str = in_str.Erase(0, ForthTerminal.DEL.Length());
			}
			else if(in_str.Find(ForthTerminal.LEFT) == 0)
			{
				_PadPosition = Mathf.Max(0, _PadPosition - 1);
				echo_text = ForthTerminal.LEFT;
				in_str = in_str.Erase(0, ForthTerminal.LEFT.Length());
			}
			else if(in_str.Find(ForthTerminal.RIGHT) == 0)
			{
				_PadPosition += 1;
				if(_PadPosition > _TerminalPad.Length())
				{
					_PadPosition = _TerminalPad.Length();
				}
				else
				{
					echo_text = ForthTerminal.RIGHT;
				}
				in_str = in_str.Erase(0, ForthTerminal.RIGHT.Length());
			}
			else if(in_str.Find(ForthTerminal.UP) == 0)
			{
				if(buffer_size)
				{
					_BufferIndex = Mathf.Max(0, _BufferIndex - 1);
					echo_text = _SelectBufferedCommand();
				}
				in_str = in_str.Erase(0, ForthTerminal.UP.Length());
			}
			else if(in_str.Find(ForthTerminal.DOWN) == 0)
			{
				if(buffer_size)
				{
					_BufferIndex = Mathf.Min(_TerminalBuffer.Size() - 1, _BufferIndex + 1);
					echo_text = _SelectBufferedCommand();
				}
				in_str = in_str.Erase(0, ForthTerminal.DOWN.Length());
			}
			else if(in_str.Find(ForthTerminal.LF) == 0)
			{
				echo_text = "";
				in_str = in_str.Erase(0, ForthTerminal.LF.Length());
			}
			else if(in_str.Find(ForthTerminal.CR) == 0)
			{
				// only add to the buffer if it's different from the top entry
				// and not blank!
				if((_TerminalPad.Length()) && (!buffer_size || (_TerminalBuffer[ - 1] != _TerminalPad)))
				{
					_TerminalBuffer.Append(_TerminalPad);
					// if we just grew too big...
					if(buffer_size == MAX_BUFFER_SIZE)
					{
						_TerminalBuffer.PopFront();
					}
				}
				_buffer_index = _terminal_buffer.size();
				// refresh the line in the terminal
				_PadPosition = _TerminalPad.Length();
				EmitSignal("TerminalOut", _RefreshEditText());
				echo_text = "";
				// text is ready for the Forth interpreter
				_InputReady.Post();
				in_str = in_str.Erase(0, ForthTerminal.CR.Length());
			}
			// not a control character(s)
			else {
				echo_text = in_str.Left(1);
				in_str = in_str.Erase(0, 1);
				foreach(string c in echo_text)
				{
					if(_PadPosition < _TerminalPad.Length())
					{
						_TerminalPad[_PadPosition] = c;
					}
					else
					{
						_TerminalPad += c;
					}
					_PadPosition += 1;
				}
			}
		}
	}


// Find word in dictionary, starting at address of top
// Returns a list consisting of:
//  > the address of the first code field (zero if not found)
//  > a boolean true if the word is defined as IMMEDIATE
	public Array FindInDict(string word)
	{
		if(DictP == DictTop)
		{
			// dictionary is empty
			return new Array{0, false, };
		}
		// stuff the search string in data memory
		Util.CstringFromStr(DICT_BUFF_START, word);
		// make a temporary pointer
		var p = DictP;
		while(p !=  - 1) // <empty>
		{
			Push(DICT_BUFF_START);	// c-addr
			Core.Count();	// search word in addr  # addr n
			Push(p + ForthRAM.CELL_SIZE);	// entry name  # addr n c-addr
			Core.Count();	// candidate word in addr			# addr n addr n
			var n_raw_length = Pop();	// addr n addr
			var n_length = n_raw_length & ~ (SMUDGE_BIT_MASK | IMMEDIATE_BIT_MASK);
			Push(n_length);	// strip the SMUDGE and IMMEDIATE bits and restore # addr n addr n
			// only check if the entry has a clear smudge bit
			if(!(n_raw_length & SMUDGE_BIT_MASK))
			{
				string.Compare();	// n
				// is this the correct entry?
				if(Pop() == 0)
				{
					// found it. Link address + link size + string length byte + string, aligned
					Push(p + ForthRAM.CELL_SIZE + 1 + n_length);	// n
					Core.Aligned(); // a
					return new Array{Pop(), (n_raw_length & IMMEDIATE_BIT_MASK) != 0, };
				}
			}
			else
			{
				// clean up the stack
				PopDword(); // addr n
				PopDword();
			}
			// not found, drill down to the next entry
			p = Ram.GetInt(p);
		}
		// exhausted the dictionary, finding nothing
		return [0, false];	
	}


// Internal utility function for creating the start of
// a dictionary entry. The next thing to follow will be
// the execution token. Upon exit, dict_top will point to the
// aligned position of the execution token to be.
// Accepts an optional smudge state (default false).
// Returns the address of the name length byte or zero on fail.
	public int CreateDictEntryName(bool smudge = false)
	{
		// ( - )
		// Grab the name
		CoreExt.ParseName();
		var len = Pop();		// length
		var caddr = Pop();		// start
		if(len <= MAX_NAME_LENGTH)
		{
			// poke address of last link at next spot, but only if this isn't
			// the very first spot in the dictionary
			if(DictTop != DictP)
			{
				// align the top pointer, so link will be word-aligned
				Core.Align();
				Ram.SetInt(DictTop, DictP);
			}
			// move the top link
			DictP = DictTop;
			SaveDictP();
			DictTop += ForthRAM.CELL_SIZE;
			// poke the name length, with a smudge bit if needed
			var smudge_bit = ( smudge ? SMUDGE_BIT_MASK : 0 );
			Ram.SetByte(DictTop, len | smudge_bit);
			// preserve the address of the length byte
			var ret = DictTop;
			DictTop += 1;
			// copy the name
			Push(caddr);
			Push(DictTop);
			Push(len);
			Core.Move();
			DictTop += len;
			Core.Align();			// will save dict_top
			// the address of the name length byte
			return ret;
		}
		return 0;
	}


// Unwind pointers and stacks to reverse the effect of any
// colon definition currently underway.
	public void UnwindCompile()
	{
		if(State)
		{
			State = false;
			// reset the control flow stack
			CfReset();
			// restore the original dictionary state
			DictTop = DictP;
			DictP = Ram.GetInt(DictP);
		}
	}

// Forth Input and Output Interface

// Register an output signal handler (port triggers message out)
// Message will fire with Forth OUT ( x p - )
	public void AddOutputSignal(int port, Signal s)
	{
		OutputPortMap[port] = s;
	}

// Register an input signal handler (message in triggers input action)
// Register a handler function with Forth LISTEN ( p xt - )
	public void AddInputSignal(int port, Signal s)
	{
		var signal_receiver = (int value) => _insert_new_event(port, value);
		s.Connect(signal_receiver);
	}


// Utility function to add an input event to the queue
	protected void _InsertNewEvent(int port, int value)
	{
		var item = new Array{port, value, };
		if(!InputPortEvents.Contains(item))
		{
			InputPortEvents.PushFront(item);
			// bump the semaphore count
			_InputReady.Post();
		}
	}


// Start a periodic timer with id to call an execution token
// This is only called from within Forth code!
	public void StartPeriodicTimer(int id, int msec, int xt)
	{
		var signal_receiver = () => _handle_timeout(id);

		// save info
		var timer = Timer.New();
		PeriodicTimerMap[id] = new Array{msec, xt, timer, };
		timer.WaitTime = msec / 1000.0;
		timer.Autostart = true;
		timer.Connect("timeout", signal_receiver);
		_Node.CallDeferred("add_child", timer);
	}


// Utility function to service periodic timer expirations
	protected void _HandleTimeout(int id)
	{
		if(!TimerEvents.Contains(id))		// don't allow timer events to stack..
		{
			TimerEvents.PushFront(id);
			// bump the semaphore count
			_InputReady.Post();
		}
	}


// Stop a timer without erasing the map entry
	protected void _StopTimer(int id)
	{
		var timer = PeriodicTimerMap[id][2];
		timer.Stop();
		_Node.RemoveChild(timer);
	}


// Stop a single timer
	protected void _RemoveTimer(int id)
	{
		if(PeriodicTimerMap.Contains(id))
		{
			_StopTimer(id);
			PeriodicTimerMap.Erase(id);
		}
	}


// Stop all timers
	protected void _RemoveAllTimers()
	{
		foreach(Dictionary id in PeriodicTimerMap)
		{
			_StopTimer(id);
		}
		PeriodicTimerMap.Clear();
	}


// Create and start all configured timers
	protected void _RestoreAllTimers()
	{
		foreach(int id in PERIODIC_TIMER_QTY)
		{
			var addr = PERIODIC_START + ForthRAM.CELL_SIZE * 2 * id;
			var msec = Ram.GetInt(addr);
			var xt = Ram.GetInt(addr + ForthRAM.CELL_SIZE);
			if(xt)
			{
				StartPeriodicTimer(id, msec, xt);
			}
		}
	}


// Forth Data Stack Push and Pop Routines

	public void Push(int val)
	{
		DsP -= 1;
		DataStack[DsP] = val;
	}


	public int Pop()
	{
		if(DsP < DATA_STACK_SIZE)
		{
			DsP += 1;
			return DataStack[DsP - 1];
		}
		Util.RprintTerm(" Data stack underflow");
		return 0;
	}


	public void PushDint(int val)
	{
		var t = Ram.Split64(val);
		Push(t[1]);
		Push(t[0]);
	}


	public int PopDint()
	{
		return Ram.Combine64(Pop(), Pop());
	}

// Forth Return Stack Push and Pop Routines

	public void RPush(int val)
	{
		RsP -= 1;
		ReturnStack[RsP] = val;
	}


	public int RPop()
	{
		if(RsP < RETURN_STACK_SIZE)
		{
			RsP += 1;
			return ReturnStack[RsP - 1];
		}
		Util.RprintTerm(" Return stack underflow");
		return 0;
	}


	public void RPushDint(int val)
	{
		var t = Ram.Split64(val);
		RPush(t[1]);
		RPush(t[0]);
	}


	public int RPopDint()
	{
		return Ram.Combine64(RPop(), RPop());
	}


// top of stack is 0, next dint is at 2, etc.
	public int GetDint(int index)
	{
		return Ram.Combine64(DataStack[DsP + index], DataStack[DsP + index + 1]);
	}


	public void SetDint(int index, int value)
	{
		var s = Ram.Split64(value);
		DataStack[DsP + index] = s[0];
		DataStack[DsP + index + 1] = s[1];
	}


	public void PushDword(int value)
	{
		var s = Ram.Split64(value);
		Push(s[1]);
		Push(s[0]);
	}


	public void SetDword(int index, int value)
	{
		var s = Ram.Split64(value);
		DataStack[DsP + index] = s[0];
		DataStack[DsP + index + 1] = s[1];
	}


	public int PopDword()
	{
		return Ram.Combine64(Pop(), Pop());
	}


// top of stack is -1, next dint is at -3, etc.
	public int GetDword(int index)
	{
		return Ram.Combine64(DataStack[DsP + index], DataStack[DsP + index + 1]);
	}


// save the internal top of dict pointer to RAM
	public void SaveDictTop()
	{
		Ram.SetInt(DICT_TOP_PTR, DictTop);
	}


// save the internal dict pointer to RAM
	public void SaveDictP()
	{
		Ram.SetInt(DICT_PTR, DictP);
	}


// retrieve the internal top of dict pointer from RAM
	public void RestoreDictTop()
	{
		DictTop = Ram.GetInt(DICT_TOP_PTR);
	}


// retrieve the internal dict pointer from RAM
	public void RestoreDictP()
	{
		DictP = Ram.GetInt(DICT_PTR);
	}
	
// dictionary instruction pointer manipulation
// push the current dict_ip
	public void PushIp()
	{
		_DictIpStack.PushBack(DictIp);
	}


	public void PopIp()
	{
		DictIp = _DictIpStack.PopBack();
	}


	public bool IpStackIsEmpty()
	{
		return _DictIpStack.Size() == 0;
	}

// compiled word control flow stack

// reset the stack
	public void CfReset()
	{
		_ControlFlowStack = new Array{};
	}


	public void LcfReset()
	{
		_LeaveControlFlowStack = new Array{};
	}


	protected void _CfPush(Godot.Variant item)
	{
		_ControlFlowStack.PushFront(item);
	}


	public void LcfPush(int item)
	{
		_LeaveControlFlowStack.PushFront(item);
	}


// push an ORIG word
	public void CfPushOrig(int addr)
	{
		_CfPush(new Array{ORIG, addr, });
	}


// push an DEST word
	public void CfPushDest(int addr)
	{
		_CfPush(new Array{DEST, addr, });
	}


// pop a word
	protected Array _CfPop()
	{
		if(!CfStackIsEmpty())
		{
			return _ControlFlowStack.PopFront();
		}
		Util.RprintTerm("Unbalanced control structure");
		return new Array{};
	}


	public int LcfPop()
	{
		return _LeaveControlFlowStack.PopFront();
	}


// check for items in the leave control flow stack
	public bool LcfIsEmpty()
	{
		return _LeaveControlFlowStack.Size() == 0;
	}


// check for ORIG at top of stack
	public bool CfIsOrig()
	{
		return _ControlFlowStack[0][0] == ORIG;
	}


// check for DEST at top of stack
	public bool CfIsDest()
	{
		return _ControlFlowStack[0][0] == DEST;
	}


// pop an ORIG word
	public int CfPopOrig()
	{
		if(_ControlFlowStack[0][0] == ORIG)
		{
			return _CfPop()[1];
		}
		Util.RprintTerm("Expected ORIG not DEST");
		return 0;
	}


// pop an DEST word
	public int CfPopDest()
	{
		if(_ControlFlowStack[0][0] == DEST)
		{
			return _CfPop()[1];
		}
		Util.RprintTerm("Expected DEST not ORIG");
		return 0;
	}


// control flow stack is empty
	public bool CfStackIsEmpty()
	{
		return _ControlFlowStack.Size() == 0;
	}


// control flow stack PICK (implements CS-PICK)
	public void CfStackPick(int item)
	{
		_CfPush(_ControlFlowStack[item]);
	}


// control flow stack ROLL (implements CS-ROLL)
	public void CfStackRoll(int item)
	{
		_CfPush(_ControlFlowStack.PopAt(item));
	}

// PRIVATES
// Called when AMCForth.new() is executed
// This will cascade instantiation of all the Forth implementation classes
// and initialize dictionaries for relating built-in words and addresses
	public void Initialize(Godot.Node node)
	{
		// save the instantiating node
		_Node = node;

		// seed the randomizer
		GD.Randomize();

		// create a config file
		_Config = ConfigFile.New();
		// the top of the dictionary can't overlap the high-memory stuff
		System.Diagnostics.Debug.Assert(DICT_TOP < PERIODIC_START);
		Ram = ForthRAM.New();
		Ram.Allocate(RAM_SIZE);
		Util = ForthUtil.New();
		Util.Initialize(this);
		// Instantiate Forth word definitions
		Core = ForthCore.New();
		Core.Initialize(this);
		CoreExt = ForthCoreExt.New();
		CoreExt.Initialize(this);
		Tools = ForthTools.New();
		Tools.Initialize(this);
		ToolsExt = ForthToolsExt.New();
		ToolsExt.Initialize(this);
		CommonUse = ForthCommonUse.New();
		CommonUse.Initialize(this);
		Double = ForthDouble.New();
		Double.Initialize(this);
		DoubleExt = ForthDoubleExt.New();
		DoubleExt.Initialize(this);
		FString = ForthString.New();
		FString.Initialize(this);
		AmcExt = ForthAMCExt.New();
		AmcExt.Initialize(this);
		Facility = ForthFacility.New();
		Facility.Initialize(this);
		FileExt = ForthFileExt.New();
		FileExt.Initialize(this);
		File = ForthFile.New();
		File.Initialize(this);

		// End Forth word definitions
		_InitBuiltIns();

		// Initialize the data stack
		DataStack.Resize(DATA_STACK_SIZE);
		DataStack.Fill(0);
		DsP = DATA_STACK_SIZE;
		// empty
		// Initialize the return stack
		ReturnStack.Resize(RETURN_STACK_SIZE);
		ReturnStack.Fill(0);
		RsP = RETURN_STACK_SIZE; // empty

		// set the terminal link in the dictionary
		Ram.SetInt(DictP,  - 1);

		// reset the buffer pointer
		Ram.SetInt(BUFF_TO_IN, 0);

		// set the base
		Core.Decimal();

		// initialize dictionary pointers and save them to RAM
		// FIXME note these have to be initialized when re-loading state
		DictP = DICT_START;
		// position of last link
		SaveDictP();
		DictTop = DICT_START;
		// position of next new link to create
		SaveDictTop();

		// Launch the AMC Forth thread
		_Thread = new System.Threading.Thread(() => _input_thread());

		// end test
		_InputReady = Semaphore.New();
		_Thread.Start();
		_OutputDone = true;
		GD.Print(_GetBanner());
	}


// AMC Forth name with version
	protected string _GetBanner()
	{
		return BANNER + " " + "Ver. " + ForthVersion.VER;
	}


	protected void _InputThread()
	{
		while(true)
		{
			_InputReady.Wait();
			
			// preferentially handle input port signals
			if(InputPortEvents.Size())
			{
				var evt = InputPortEvents.PopBack();

				// only execute if Forth is listening on this port
				var xt = Ram.GetInt(IO_IN_MAP_START + evt[0] * ForthRAM.CELL_SIZE);
				if(xt)
				{
					Push(evt[1]);
					// store the value
					Push(xt);
					// push the xt
					Core.Execute();
				}
			}

			// followed by timer timeouts
			else if(TimerEvents.Size())
			{
				var id = TimerEvents.PopBack();

				// only execute if Forth is still listening on this id
				var xt = Ram.GetInt(PERIODIC_START + (id * 2 + 1) * ForthRAM.CELL_SIZE);
				if(xt)
				{
					Push(xt);
					Core.Execute();
				}
				else
				{
					// not listening any longer. remove the timer.
					CallDeferred("_remove_timer", id);
				}
			}
			else
			{
				// no input events, must be terminal input line
				_OutputDone = false;
				_InterpretTerminalLine();
				_OutputDone = true;
			}
		}
	}


// generate execution tokens by hashing Forth Word
	public int XtFromWord(string word)
	{
		return BUILT_IN_XT_MASK + (BUILT_IN_MASK & word.Hash());
	}


// generate run-time execution tokens by hashing Forth Word
	public int XtxFromWord(string word)
	{
		return BUILT_IN_XTX_MASK + (BUILT_IN_MASK & word.Hash());
	}


	protected void _InitBuiltIns()
	{
		var addr;
		foreach(int i in BuiltInNames.Size())
		{
			var word = BuiltInNames[i][0];
			var f = BuiltInNames[i][1];

			// native functions are assigned virtual addresses, outside of
			// the real memory map.
			addr = XtFromWord(word);
			System.Diagnostics.Debug.Assert(!BuiltInFunctionFromAddress.ContainsKey(addr), "Duplicate Forth word hash must be resolved.");
			BuiltInFunctionFromAddress[addr] = f;
			AddressFromBuiltInFunction[f] = addr;
			BuiltInFunction[word] = f;
		}
		foreach(int i in BuiltInExecFunctions.Size())
		{
			var word = BuiltInExecFunctions[i][0];
			var f = BuiltInExecFunctions[i][1];
			addr = XtxFromWord(word);
			BuiltInFunctionFromAddress[addr] = f;
			AddressFromBuiltInFunction[f] = addr;
		}
	}


	public void ResetBuffToIn()
	{
		// retrieve the address of the current buffer pointer
		Core.ToIn();

		// and set its contents to zero
		Ram.SetInt(Pop(), 0);
	}


	public bool IsValidInt(string word, int radix = 10)
	{
		if(radix == 16)
		{
			return word.IsValidHexNumber();
		}
		return word.IsValidInt();
	}


	public int ToInt(string word, int radix = 10)
	{
		if(radix == 16)
		{
			return word.HexToInt();
		}
		return word.ToInt();
	}



// Given a word, determine if it is immediate or not.
	public bool IsImmediate(string word)
	{
		return ImmediateNames.Contains(word);
	}


// Interpret the _terminal_pad content
	protected void _InterpretTerminalLine()
	{
		var bytes_input = _TerminalPad.ToAsciiBuffer();
		_TerminalPad = "";
		_PadPosition = 0;
		bytes_input.PushBack(0);
		// null terminate
		// transfer to the RAM-based input buffer (accessible to the engine)
		foreach(int i in bytes_input.Size())
		{
			Ram.SetByte(BUFF_SOURCE_START + i, bytes_input[i]);
		}
		Push(BUFF_SOURCE_START);
		Push(bytes_input.Size());
		SourceId =  - 1;
		Core.Evaluate();
		Util.RprintTerm(" ok");
	}


// return echo text that refreshes the current edit
	protected string _RefreshEditText()
	{
		var echo = ForthTerminal.CLRLINE
			+ ForthTerminal.CR
			+ _TerminalPad
			+ ForthTerminal.CR;
			
		foreach(int i in GD.Range(_PadPosition))
		{
			echo += ForthTerminal.RIGHT;
		}
		return echo;
	}


	protected string _SelectBufferedCommand()
	{
		var selected_index = _BufferIndex;
		_TerminalPad = _TerminalBuffer[selected_index];
		_PadPosition = _TerminalPad.Length();
		return ForthTerminal.CLRLINE + ForthTerminal.CR + _TerminalPad;
	}
}
