using System;
using System.Data.SqlTypes;
using System.Runtime.InteropServices;
using Godot;
using Godot.Collections;

// Definitions for working with "physical" RAM
//
// (1) Defines the size of a Forth cell and double-cell

// (2) Functions for setting and getting numbers in RAM


// cell size should be 2 or 4
// if 2, use (encode|decode)_(s|u)16 and (encode|decode)_(s_u)32
// if 4, use (encode|decode)_(s|u)32 and (encode|decode)_(s_u)64
[GlobalClass]
public partial class ForthRAM : Godot.RefCounted
{
	public const int CellSize = 4;
	public const int DCellSize = CellSize * 2;
	public const int CellBits = CellSize * 8;
	public const int DCellBits = CellBits * 2;
	public const int CellMask = -1;  // FIXME how is this being used?
	public const int CELL_MAX_WORD = -1;  // FIXME how is this being used?
	public const int CELL_MAX_POSITIVE = int.MaxValue;
	public const int CELL_MAX_NEGATIVE =  int.MinValue;


	// buffer for all physical RAM
	protected byte[] _Ram;


	// save ram state
	public void SaveState(Godot.ConfigFile config)
	{
		config.SetValue("ram", "image", _Ram);
	}


// restore ram state
	public void LoadState(Godot.ConfigFile config)
	{
		_Ram = config.GetValue("ram", "image").AsByteArray();
	}


// allocate memory for RAM and a DCELL_SIZE scratchpad
	public void Allocate(int size)
	{
		_Ram = new byte[size];
	}


// convert int to standard forth ordering and vice versa
	protected ulong DSwap(ulong num)
	{
		return (num / ((ulong) uint.MaxValue+1)) + num * ((ulong) uint.MaxValue+1);
	}

	// 32 to 64-bit conversions

	// structure of double int
	public readonly struct Double
	{
		public Double(long lo, long hi)
		{
			Lo = lo;
			Hi = hi;
		}

		public long Lo { get; }
		public long Hi { get;}

		public override string ToString() => $"(L:{Lo}, H:{Hi})";
	}


	// convert int to [hi, lo] 32-bit words
	public static Double Split64(long val)
	{
		return new Double(val & (long) uint.MaxValue, val / ((long) uint.MaxValue+1));
	}


// convert (hi, lo) to 64-bit int
	public static long Combine64(int hi, int lo)
	{
		return hi * ((long) uint.MaxValue + 1) + lo;
	}


// return just the cell-sized low-order portion of 64-bit int
	public static int TruncateToCell(long val)
	{
		return Convert.ToInt32(Split64(val).Lo);
	}


// Data stack and RAM helpers
	public void SetByte(int addr, int val)
	{
		_Ram[addr] = (byte) val;
	}


	public int GetByte(int addr)
	{
		return _Ram[addr];
	}

	// signed cell-sized values

	public void SetInt(int addr, int val)
	{
		Span<byte> bytes = _Ram;
		System.Buffers.Binary.BinaryPrimitives.WriteInt32BigEndian(bytes.Slice(addr, sizeof(int)), val);
	}


	public int GetInt(int addr)
	{
		Span<byte> bytes = _Ram;
		return System.Buffers.Binary.BinaryPrimitives.ReadInt32BigEndian(bytes.Slice(addr, sizeof(int)));
	}


// unsigned cell-sized values
	public void SetWord(int addr, uint val)
	{
		Span<byte> bytes = _Ram;
		System.Buffers.Binary.BinaryPrimitives.WriteUInt32BigEndian(bytes.Slice(addr, sizeof(int)), val);
	}


	public uint GetWord(int addr)
	{
		Span<byte> bytes = _Ram;
		return System.Buffers.Binary.BinaryPrimitives.ReadUInt32BigEndian(bytes.Slice(addr, sizeof(uint)));
	}


// signed double-precision values - same split as on Forth stack
	public void SetDint(int addr, long val)
	{
		var split_long = Split64(val);
		SetInt(addr, (int) split_long.Hi);
		SetInt(addr + sizeof(int), (int) split_long.Lo);
	}


	public long GetDint(int addr)
	{
		return Combine64(GetInt(addr), GetInt(addr + sizeof(int)));
	}


// unsigned double-precision values
	public void SetDword(int addr, ulong val)
	{
		var split_long = Split64((long) val);
		SetWord(addr, (uint) split_long.Hi);
		SetWord(addr + sizeof(uint), (uint) split_long.Lo);
	}


	public ulong GetDword(int addr)
	{
		return (ulong) Combine64((int)GetWord(addr), (int)GetWord(addr + sizeof(int)));
	}
}
