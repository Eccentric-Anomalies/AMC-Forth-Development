using System;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.InteropServices;
using Forth.CommonUse;
using Godot;
// Forth CORE word set

namespace Forth.Core
{

	[GlobalClass]
	public partial class CoreSet : Godot.RefCounted
	{

		public Align Align;
		public Aligned Aligned;
		public Base Base;
		public Cells Cells;
		public Comma Comma;
		public Count Count;
		public Decimal Decimal;
		public Drop Drop;
		public Dup Dup;
		public Evaluate Evaluate;
		public Execute Execute;
		public Literal Literal;
		public Minus Minus;
		public Move Move;
		public Over Over;		
		public Plus Plus;
		public Source Source;
		public Star Star;
		public Store Store;
		public Swap Swap;
		public Tick Tick;
		public ToIn ToIn;
		public TwoStar TwoStar;
		public Word Word;
		public ZeroEqual ZeroEqual;

		private const string Wordset = "CORE"; 

        public CoreSet(AMCForth _forth)
        {
			Align = new (_forth, Wordset);
			Aligned = new (_forth, Wordset);
			Base = new (_forth, Wordset);
			Cells = new (_forth, Wordset);
			Comma = new (_forth, Wordset);
			Count = new (_forth, Wordset);
			Decimal = new (_forth, Wordset);
			Drop = new (_forth, Wordset);
			Dup = new (_forth, Wordset);
			Evaluate = new (_forth, Wordset);
			Execute = new (_forth, Wordset);
			Literal = new (_forth, Wordset);
			Minus = new(_forth, Wordset);
			Move = new(_forth, Wordset);
			Over = new (_forth, Wordset);
			Plus = new (_forth, Wordset);
			Source = new (_forth, Wordset);
			Star = new (_forth, Wordset);
			Store = new (_forth, Wordset);
			Swap = new (_forth, Wordset);
			Tick = new (_forth, Wordset);
			ToIn = new (_forth, Wordset);
			TwoStar = new (_forth, Wordset);
			Word = new (_forth, Wordset);
			ZeroEqual = new(_forth, Wordset);
        }

	}
}