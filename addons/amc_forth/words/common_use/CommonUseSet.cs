using Godot;
// Forth COMMON USE word set

namespace Forth.CommonUse
{

	[GlobalClass]
	public partial class CommonUseSet : Godot.RefCounted
	{
		public NumberQuestion NumberQuestion;
		private const string Wordset = "COMMON USE"; 

        public CommonUseSet(AMCForth _forth)
        {
			NumberQuestion = new (_forth, Wordset);
        }
	}
}