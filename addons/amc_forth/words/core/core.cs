using Godot;
// Forth CORE word set

namespace Forth.Core
{

	[GlobalClass]
	public partial class Core : Godot.RefCounted
	{
		public AMCForth Forth;

		private const string WORDSET = "CORE"; 

		// Words in Core
		public Forth.Core.Count Count;
		public Forth.Core.Aligned Aligned;
		public Forth.Core.Align Align;
		public Forth.Core.Word Word;
		public Forth.Core.Move Move;

        public Core(AMCForth _forth)
        {
            Forth = _forth;
			// Instantiate the word definitions
			Count = new(_forth, WORDSET);
			Aligned = new(_forth, WORDSET);
			Word = new(_forth, WORDSET);
			Move = new(_forth, WORDSET);
        }


	}
}