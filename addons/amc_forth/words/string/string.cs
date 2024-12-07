using Godot;
// Forth STRING word set

namespace Forth.String
{

	[GlobalClass]
	public partial class String : Godot.RefCounted
	{
		public AMCForth Forth;
		private const string WORDSET = "STRING"; 

		// Words in String
		public Forth.String.Compare Compare;

        public String(AMCForth _forth)
        {
            Forth = _forth;
			// Instantiate the word definitions
			Compare = new(_forth, WORDSET);
        }


	}
}