using Godot;
// Base class and utilities for Forth word definition

namespace Forth
{

	[GlobalClass]
	public partial class WordBase : Godot.RefCounted
	{
		public AMCForth Forth;
		public bool Immediate;
		public string Name;
		public string Description;
		public string StackEffect;
		public string WordSet;

        public WordBase(AMCForth forth, string wordset)
        {
            Forth = forth;
			Immediate = false;
			WordSet = wordset;
        }

        public virtual void Execute()
		{
		}

		public virtual void Compiled()
		{
		}

	}
}