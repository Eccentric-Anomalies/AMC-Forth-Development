using Godot;
using Godot.Collections;

//# Forth internal utilities

//#


[GlobalClass]
public partial class ForthUtil : Godot.RefCounted
{
	protected AMCForth _Forth;


	//# Create with a reference to AMCForth
	public void Initialize(AMCForth forth)
	{
		_Forth = forth;
	}


//# Send a newline character to the terminal out
	public void EmitNewline()
	{
		_Forth.EmitSignal("TerminalOut", ForthTerminal.CR + ForthTerminal.LF);
	}


//# Send text to the terminal out, with a following newline
	public void RprintTerm(string text)
	{
		PrintTerm(text);
		EmitNewline();
	}


//# Send text to the terminal out
	public void PrintTerm(string text)
	{
		_Forth.EmitSignal("TerminalOut", text);
	}


//# Report an unrecognized Forth word
	public void PrintUnknownWord(string word)
	{
		RprintTerm(" " + word + " ?");
	}


//# Return a gdscript string from address and length
	public string StrFromAddrN(int addr, int n)
	{
		var t = "";
		foreach(int c in n)
		{
			t = t + Char(_Forth.Ram.GetByte(addr + c));
		}
		return t;
	}


//# Create a Forth counted string frm a gdscript string
	public void CstringFromStr(int addr, string s)
	{
		var n = addr;
		_Forth.Ram.SetByte(n, s.Length());
		n += 1;
		foreach(PackedByteArray c in s.ToAsciiBuffer())
		{
			_Forth.Ram.SetByte(n, c);
			n += 1;
		}
	}


//# Copy at most n string characters to address
	public void StringFromStr(int addr, int n, string s)
	{
		var ptr = addr;
		foreach(PackedByteArray c in s.Substr(0, n).ToAsciiBuffer())
		{
			_Forth.Ram.SetByte(ptr, c);
			ptr += 1;
		}
	}


}
