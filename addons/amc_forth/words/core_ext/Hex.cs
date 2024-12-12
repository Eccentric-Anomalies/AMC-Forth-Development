using Godot;

namespace Forth.CoreExt
{
[GlobalClass]
	public partial class Hex : Forth.Words
	{

		public Hex(AMCForth forth, string wordset) : base(forth, wordset)
		{
			Name = "HEX";
			Description = "Sets BASE to 16.";
			StackEffect = "( - )";
		}

		public override void Call()
		{
			Forth.Push(16);
			Forth.CoreWords.Base.Call();
			Forth.CoreWords.Store.Call();
		}
	}
}