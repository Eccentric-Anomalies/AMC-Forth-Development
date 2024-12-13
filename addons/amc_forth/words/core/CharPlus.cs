using Godot;

namespace Forth.Core
{
[GlobalClass]
	public partial class CharPlus : Forth.Words
	{

		public CharPlus(AMCForth forth, string wordset) : base(forth, wordset)
		{			
			Name = "CHAR+";
			Description = "Add the size in bytes of a character to c_addr1, giving c-addr2.";
			StackEffect = "( c-addr1 - c-addr2 )";
		}

		public override void Call()
		{
			Forth.Push(1);
			Forth.CoreWords.Plus.Call();
		}
	}
}