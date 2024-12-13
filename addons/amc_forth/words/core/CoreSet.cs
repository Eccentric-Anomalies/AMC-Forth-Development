using System;
using System.Collections.Generic;
using System.Reflection;
using System.Reflection.Metadata;
using System.Runtime.InteropServices;
using Forth.CommonUse;
using Forth.CoreExt;
using Forth.Double;
using Godot;
// Forth CORE word set

namespace Forth.Core
{

	[GlobalClass]
	public partial class CoreSet : Godot.RefCounted
	{
		public Abs Abs;
		public Align Align;
		public Aligned Aligned;
		public Allot Allot;
		public And And;
		public Base Base;
		public Begin Begin;
		public BL BL;
		public CellPlus CellPlus;
		public CComma CComma;
		public Cells Cells;
		public CFetch CFetch;
		public CharPlus CharPlus;
		public Chars Chars;
		public Colon Colon;
		public Comma Comma;
		public Constant Constant;
		public Count Count;
		public CR CR;
		public Create Create;
		public CStore CStore;
		public Decimal Decimal;
		public Depth Depth;
		public Do Do;
		public Dot Dot;
		public DotQuote DotQuote;
		public Drop Drop;
		public Dup Dup;
		public Emit Emit;
		public Equal Equal;
		public Fetch Fetch;
		public GreaterThan GreaterThan;
		public Else Else;
		public Evaluate Evaluate;
		public Execute Execute;
		public Exit Exit;
		public Here Here;
		public I I;
		public If If;
		public Immediate Immediate;
		public Invert Invert;
		public J J;
		public Leave Leave;
		public LeftBracket LeftBracket;
		public LeftParenthesis LeftParenthesis;
		public LessThan LessThan;
		public Literal Literal;
		public LShift LShift;
		public Loop Loop;
		public Max Max;
		public Min Min;
		public Minus Minus;
		public Mod Mod;
		public Move Move;
		public MStar MStar;
		public Negate Negate;
		public OnePlus OnePlus;
		public OneMinus OneMinus;
		public Or Or;
		public Over Over;		
		public Plus Plus;
		public PlusLoop PlusLoop;
		public PlusStore PlusStore;
		public Postpone Postpone;
		public QuestionDo QuestionDo;
		public QuestionDup QuestionDup;
		public Repeat Repeat;
		public RFetch RFetch;
		public RFrom RFrom;
		public RightBracket RightBracket;
		public Rot Rot;
		public RShift RShift;
		public SemiColon SemiColon;
		public Slash Slash;
		public SlashMod SlashMod;
		public SmSlashRem SmSlashRem;
		public Source Source;
		public Space Space;
		public Spaces Spaces;
		public SQuote SQuote;
		public Star Star;
		public StarSlash StarSlash;
		public StarSlashMod StarSlashMod;
		public SToD SToD;
		public Store Store;
		public Swap Swap;
		public Then Then;
		public Tick Tick;
		public ToBody ToBody;
		public ToIn ToIn;
		public ToR ToR;
		public TwoDrop TwoDrop;
		public TwoDup TwoDup;
		public TwoFetch TwoFetch;
		public TwoOver TwoOver;
		public TwoSlash TwoSlash;
		public TwoStar TwoStar;
		public TwoStore TwoStore;
		public TwoSwap TwoSwap;
		public Core.Type Type;
		public UmSlashMod UmSlashMod;
		public UmStar UmStar;
		public Unloop Unloop;
		public Until Until;
		public ULessThan ULessThan;
		public Variable Variable;
		public While While;
		public Word Word;
		public Xor Xor;
		public ZeroEqual ZeroEqual;
		public ZeroLessThan ZeroLessThan;

		private const string Wordset = "CORE"; 

        public CoreSet(AMCForth _forth)
        {
			Abs = new (_forth, Wordset);
			Align = new (_forth, Wordset);
			Aligned = new (_forth, Wordset);
			Allot = new (_forth, Wordset);
			And = new (_forth, Wordset);
			Base = new (_forth, Wordset);
			Begin = new (_forth, Wordset);
			BL = new (_forth, Wordset);
			CComma = new (_forth, Wordset);
			CellPlus = new (_forth, Wordset);
			Cells = new (_forth, Wordset);
			CFetch = new (_forth, Wordset);
			CharPlus = new (_forth, Wordset);
			Chars = new (_forth, Wordset);
			Colon = new (_forth, Wordset);
			Comma = new (_forth, Wordset);
			Constant = new (_forth, Wordset);
			Count = new (_forth, Wordset);
			CR = new (_forth, Wordset);
			Create = new (_forth, Wordset);
			CStore = new (_forth, Wordset);
			Decimal = new (_forth, Wordset);
			Depth = new (_forth, Wordset);
			Do = new (_forth, Wordset);
			Dot = new (_forth, Wordset);
			DotQuote = new (_forth, Wordset);
			Drop = new (_forth, Wordset);
			Dup = new (_forth, Wordset);
			Else = new (_forth, Wordset);
			Emit = new (_forth, Wordset);
			Equal = new (_forth, Wordset);
			Evaluate = new (_forth, Wordset);
			Execute = new (_forth, Wordset);
			Exit = new (_forth, Wordset);
			GreaterThan = new (_forth, Wordset);
			LeftParenthesis = new (_forth, Wordset);
			Fetch = new (_forth, Wordset);
			Here = new (_forth, Wordset);
			I = new (_forth, Wordset);
			If = new (_forth, Wordset);
			Immediate = new (_forth, Wordset);
			Invert = new (_forth, Wordset);
			J = new (_forth, Wordset);
			Leave = new (_forth, Wordset);
			LeftBracket = new (_forth, Wordset);
			LessThan = new (_forth, Wordset);
			Literal = new (_forth, Wordset);
			LShift = new (_forth, Wordset);
			Loop = new (_forth, Wordset);
			Max = new (_forth, Wordset);
			Min = new (_forth, Wordset);
			Minus = new (_forth, Wordset);
			Mod = new (_forth, Wordset);
			Move = new (_forth, Wordset);
			MStar = new (_forth, Wordset);
			Negate = new (_forth, Wordset);
			OnePlus = new (_forth, Wordset);
			OneMinus = new (_forth, Wordset);
			Or = new (_forth, Wordset);
			Over = new (_forth, Wordset);
			Plus = new (_forth, Wordset);
			PlusLoop = new (_forth, Wordset);
			PlusStore = new (_forth, Wordset);
			Postpone = new (_forth, Wordset);
			QuestionDo = new (_forth, Wordset);
			QuestionDup = new (_forth, Wordset);
			Repeat = new (_forth, Wordset);
			RFetch = new (_forth, Wordset);
			RFrom = new (_forth, Wordset);
			RightBracket = new (_forth, Wordset);
			Rot = new (_forth, Wordset);
			RShift = new (_forth, Wordset);
			SQuote = new (_forth, Wordset);
			SemiColon = new (_forth, Wordset);
			Slash = new (_forth, Wordset);
			SlashMod = new (_forth, Wordset);
			SmSlashRem = new (_forth, Wordset);
			Source = new (_forth, Wordset);
			Space = new (_forth, Wordset);
			Spaces = new (_forth, Wordset);
			Star = new (_forth, Wordset);
			StarSlash = new (_forth, Wordset);
			StarSlashMod = new (_forth, Wordset);
			SToD = new (_forth, Wordset);
			Store = new (_forth, Wordset);
			Swap = new (_forth, Wordset);
			Then = new (_forth, Wordset);
			Tick = new (_forth, Wordset);
			ToBody = new (_forth, Wordset);
			ToIn = new (_forth, Wordset);
			ToR = new (_forth, Wordset);
			TwoDrop = new (_forth, Wordset);
			TwoDup = new (_forth, Wordset);
			TwoFetch = new (_forth, Wordset);
			TwoOver = new (_forth, Wordset);
			TwoSlash = new (_forth, Wordset);
			TwoStar = new (_forth, Wordset);
			TwoStore = new (_forth, Wordset);
			TwoSwap = new (_forth, Wordset);
			Type = new (_forth, Wordset);
			UmSlashMod = new (_forth, Wordset);
			UmStar = new (_forth, Wordset);
			Unloop = new (_forth, Wordset);
			Until = new (_forth, Wordset);
			ULessThan = new (_forth, Wordset);
			Variable = new (_forth, Wordset);
			While = new (_forth, Wordset);
			Word = new (_forth, Wordset);
			Xor = new (_forth, Wordset);
			ZeroEqual = new (_forth, Wordset);
			ZeroLessThan = new (_forth, Wordset);
        }
	}
}