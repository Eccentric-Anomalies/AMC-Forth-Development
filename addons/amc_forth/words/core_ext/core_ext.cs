using Godot;
// Forth CORE EXT word set

namespace Forth.CoreExt
{

	[GlobalClass]
	public partial class CoreExt : Godot.RefCounted
	{
		public AMCForth Forth;
		private const string WORDSET = "CORE EXT"; 

		// Words in String
		public Forth.CoreExt.ParseName ParseName;

        public CoreExt(AMCForth _forth)
        {
            Forth = _forth;
			// Instantiate the word definitions
			ParseName = new(_forth, WORDSET);
        }
	}
}