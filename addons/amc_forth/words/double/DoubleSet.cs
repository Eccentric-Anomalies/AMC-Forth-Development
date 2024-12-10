using Godot;
// Forth STRING word set

namespace Forth.Double
{
	[GlobalClass]
	public partial class DoubleSet : Godot.RefCounted
	{
		public TwoLiteral TwoLiteral;
		private const string Wordset = "DOUBLE"; 

        public DoubleSet(AMCForth _forth)
        {
			TwoLiteral = new (_forth, Wordset);
        }

	}
}