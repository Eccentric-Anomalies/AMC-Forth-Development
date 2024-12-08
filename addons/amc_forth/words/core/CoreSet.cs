using System;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.InteropServices;
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
		public Count Count;
		public Decimal Decimal;
		public Drop Drop;
		public Dup Dup;
		public Source Source;
		public Store Store;
		public ToIn ToIn;
		public Word Word;
		public Move Move;

		private const string Wordset = "CORE"; 

        public CoreSet(AMCForth _forth)
        {
			Align = new (_forth, Wordset);
			Aligned = new (_forth, Wordset);
			Base = new (_forth, Wordset);
			Count = new (_forth, Wordset);
			Decimal = new (_forth, Wordset);
			Drop = new (_forth, Wordset);
			Dup = new (_forth, Wordset);
			Source = new (_forth, Wordset);
			Store = new (_forth, Wordset);
			ToIn = new (_forth, Wordset);
			Word = new (_forth, Wordset);
			Move = new(_forth, Wordset);
        }

	}
}