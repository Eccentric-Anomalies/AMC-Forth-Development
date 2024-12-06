using Godot;
using Godot.Collections;

//# Definitions for working with "physical" RAM
//#
//# (1) Defines the size of a Forth cell and double-cell

//# (2) Functions for setting and getting numbers in RAM


// cell size should be 2 or 4
// if 2, use (encode|decode)_(s|u)16 and (encode|decode)_(s_u)32
// if 4, use (encode|decode)_(s|u)32 and (encode|decode)_(s_u)64
[GlobalClass]
public partial class ForthRAM : Godot.RefCounted
{
	public const int CELL_SIZE = 4;
	public const int DCELL_SIZE = CELL_SIZE * 2;
	public const int CELL_BITS = CELL_SIZE * 8;
	public const int DCELL_BITS = CELL_BITS * 2;
	public const int CELL_MASK = -1;  // FIXME how is this being used?
	public const int CELL_MAX_WORD = -1;  // FIXME how is this being used?
	public const int CELL_MAX_POSITIVE = int.MaxValue;
	public const int CELL_MAX_NEGATIVE =  int.MinValue;


	// buffer for all physical RAM
	protected byte[] _Ram;


	// forth ordering scratch
	protected byte[] _DScratch;


	// save ram state
	public void SaveState(Godot.ConfigFile config)
	{
		config.SetValue("ram", "image", _Ram);
	}


// restore ram state
	public void LoadState(Godot.ConfigFile config)
	{
		_Ram = config.GetValue("ram", "image");
	}


// allocate memory for RAM and a DCELL_SIZE scratchpad
	public void Allocate(int size)
	{
		_Ram = new byte[size];
		_DScratch = new byte[DCELL_SIZE];
	}


// convert int to standard forth ordering and vice versa
	protected int _DSwap(int num)
	{
		_DScratch.EncodeS64(0, num);
		var t = _DScratch.DecodeS32(0);
		_DScratch.EncodeS32(0, _DScratch.DecodeS32(CELL_SIZE));
		_DScratch.EncodeS32(CELL_SIZE, t);
		return _DScratch.DecodeS64(0);


	// 32 to 64-bit conversions

	}// convert int to [hi, lo] 32-bit words
	public Array Split64(int val)
	{
		_DScratch.EncodeS64(0, val);
		return new Array{_DScratch.DecodeS32(4), _DScratch.DecodeS32(0), };
	}


// convert (hi, lo) to 64-bit int
	public int Combine64(int hi, int lo)
	{
		_DScratch.EncodeS32(4, hi);
		_DScratch.EncodeS32(0, lo);
		return _DScratch.DecodeS64(0);
	}


// return just the cell-sized low-order portion of 64-bit int
	public int TruncateToCell(int val)
	{
		if(val > CELL_MAX_POSITIVE || val < CELL_MAX_NEGATIVE)
		{
			return Split64(val)[1];
		}
		return val;
	}


// Data stack and RAM helpers
	public void SetByte(int addr, int val)
	{
		_Ram.EncodeU8(addr, val);
	}


	public int GetByte(int addr)
	{
		return _Ram.DecodeU8(addr);


	// signed cell-sized values

	}// convert cell-size signed to unsigned value
	public int Unsigned(int val)
	{
		return (uint)val;
	}


	public void SetInt(int addr, int val)
	{
		_Ram.EncodeS32(addr, val);
	}


	public int GetInt(int addr)
	{
		return _Ram.DecodeS32(addr);
	}


// unsigned cell-sized values
	public void SetWord(int addr, int val)
	{
		_Ram.EncodeU32(addr, val);
	}


	public int GetWord(int addr)
	{
		return _Ram.DecodeU32(addr);
	}


// signed double-precision values
	public void SetDint(int addr, int val)
	{
		_Ram.EncodeS64(addr, _DSwap(val));
	}


	public int GetDint(int addr)
	{
		return _DSwap(_Ram.DecodeS64(addr));
	}


// unsigned double-precision values
	public void SetDword(int addr, int val)
	{
		_Ram.EncodeU64(addr, _DSwap(val));
	}


	public int GetDword(int addr)
	{
		return _DSwap(_Ram.DecodeU64(addr));
	}


}
