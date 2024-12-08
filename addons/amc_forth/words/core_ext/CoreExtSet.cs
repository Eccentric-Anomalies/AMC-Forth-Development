using Godot;
// Forth CORE EXT word set

namespace Forth.CoreExt
{

	[GlobalClass]
	public partial class CoreExtSet : Godot.RefCounted
	{
		public Parse Parse;
		public ParseName ParseName;
		private const string Wordset = "CORE EXT"; 

        public CoreExtSet(AMCForth _forth)
        {
			Parse = new (_forth, Wordset);
			ParseName = new (_forth, Wordset);
        }
	}
}